import os
import json
import logging
from typing import AsyncGenerator

from fastapi import FastAPI
from starlette.requests import Request
from starlette.responses import StreamingResponse, JSONResponse
from ray import serve

os.environ["VLLM_USE_FLASHINFER_MOE_MXFP4_MXFP8"] = "1"

os.environ["VLLM_LOG_STATS_INTERVAL"] = "5.0"  # Log throughput every 2 seconds
os.environ["RAY_SERVE_QUEUE_LENGTH_RESPONSE_DEADLINE_S"] = "1.0" # Fix timeout warning
# VLLM Imports
from vllm.engine.arg_utils import AsyncEngineArgs
from vllm.engine.async_llm_engine import AsyncLLMEngine
from vllm.entrypoints.openai.serving_chat import OpenAIServingChat
from vllm.entrypoints.openai.serving_models import OpenAIServingModels, BaseModelPath
from vllm.entrypoints.openai.protocol import ChatCompletionRequest, StructuredOutputsParams
from vllm.v1.metrics.ray_wrappers import RayPrometheusStatLogger

class RayServeLogFilter(logging.Filter):
    """
    Filters out the specific Ray Serve request success logs.
    Targeting: 'default_VLLMDeployment ... POST /v1/chat/completions 200'
    """
    def filter(self, record: logging.LogRecord) -> bool:
        msg = record.getMessage()
        # If it's a success log, block it (False)
        if "POST /v1/chat/completions 200" in msg:
            return False
        # Let errors and vLLM stats pass through (True)
        return True


# --- LOGGING CONFIGURATION ---
class UvicornLogFilter(logging.Filter):
    """
    Filters out HTTP 200 OK access logs to reduce noise during benchmarking.
    Keeps 4xx and 5xx errors visible.
    """
    def filter(self, record: logging.LogRecord) -> bool:
        # Standard Uvicorn access log message: '... "POST /..." 200 OK'
        log_msg = record.getMessage()
        if " 200 OK" in log_msg:
            return False
        return True

app = FastAPI()

num_replicas = 5
gpu_memory_utilization = 0.95 / num_replicas

@serve.deployment(
    num_replicas=num_replicas, 
    ray_actor_options={"num_gpus": gpu_memory_utilization},
    max_ongoing_requests=400,
    graceful_shutdown_timeout_s=20
)
@serve.ingress(app)
class VLLMDeployment:
    def __init__(self):

        # 1. Get the Ray Serve logger
        ray_logger = logging.getLogger("ray.serve")
        context = serve.get_replica_context()
        self.replica_rank = context.rank
        
        # 2. Ensure it allows INFO logs (so stats can pass)
        ray_logger.setLevel(logging.INFO)
        
        # 3. Apply the surgical filter to remove only the request spam
        ray_logger.addFilter(RayServeLogFilter())
        
        # 4. Keep Uvicorn silent too
        logging.getLogger("uvicorn.access").addFilter(UvicornLogFilter())
        
        self.model_name = "openai/gpt-oss-20b"
        
        # 2. CONFIGURE ENGINE METRICS
        args = AsyncEngineArgs(
            model=self.model_name,
            tensor_parallel_size=1,
            gpu_memory_utilization=gpu_memory_utilization,
            trust_remote_code=True,
            quantization="mxfp4",
            max_num_seqs=128,
            max_model_len=16384,
            
            disable_log_stats=False,   # Ensure stats are ON
        )
        
        self.engine = AsyncLLMEngine.from_engine_args(
            args, 
            stat_loggers=[RayPrometheusStatLogger]
        )


        self.openai_serving_chat = None
    
    def __del__(self):
        """
        Attempt to clean up the vLLM engine when the Ray actor is killed.
        This helps silence the 'NCCL' and 'nanobind' warnings.
        """
        if hasattr(self, 'engine'):
            # This forces Python to garbage collect the engine object,
            # which triggers the internal C++ cleanup routines.
            del self.engine

    async def _ensure_openai_serving_chat(self):
        if self.openai_serving_chat is None:
            base_model_paths = [
                BaseModelPath(name=self.model_name, model_path=self.model_name)
            ]
            
            serving_models = OpenAIServingModels(
                engine_client=self.engine,
                base_model_paths=base_model_paths,
            )
            
            self.openai_serving_chat = OpenAIServingChat(
                self.engine,
                serving_models, 
                "assistant", 
                request_logger=None,
                chat_template=None, 
                chat_template_content_format="auto",
            )

    @app.post("/v1/chat/completions")
    async def create_chat_completion(self, raw_request: Request):
        await self._ensure_openai_serving_chat()
        
        request_dict = await raw_request.json()
        
        # Clean out guided params to avoid Pydantic warnings
        guided_json = request_dict.pop("guided_json", None)
        guided_regex = request_dict.pop("guided_regex", None)
        guided_choice = request_dict.pop("guided_choice", None)
        guided_grammar = request_dict.pop("guided_grammar", None)
        guided_backend = request_dict.pop("guided_decoding_backend", None)
        guided_whitespace = request_dict.pop("guided_whitespace_pattern", None)

        request = ChatCompletionRequest.model_validate(request_dict)
        
        if any([guided_json, guided_regex, guided_choice, guided_grammar]):
            request.structured_outputs = StructuredOutputsParams(
                json=guided_json,
                regex=guided_regex,
                choice=guided_choice,
                grammar=guided_grammar,
                backend=guided_backend,
                whitespace_pattern=guided_whitespace
            )

        request.stream = False

        result = await self.openai_serving_chat.create_chat_completion(
            request, raw_request
        )

        return JSONResponse(content=result.model_dump())

# Global deployment object for 'serve run'
deployment = VLLMDeployment.bind()

if __name__ == "__main__":
    serve.start(http_options={"port": 8000, "request_timeout_s": 1800})
    deployment.run()
        
    try:
        import time
        while True:
            time.sleep(10)
    except KeyboardInterrupt:
        print("Shutting down...")
        serve.shutdown()