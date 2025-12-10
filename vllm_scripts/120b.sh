source ~/vllm_env/bin/activate
vllm serve openai/gpt-oss-120b \
    --gpu-memory-utilization 0.75 \
    --host 127.0.0.1 \
    --max-num-seqs 32 \
    --enable-chunked-prefill \
    --port 8000 \
    --max-model-len 8192 