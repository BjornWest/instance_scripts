source ~/vllm_env/bin/activate

# Ensure only the quantized model files are checked, explicitly excluding the large 'original' and 'metal' directories
echo "Checking model files (ignoring 'original' and 'metal' folders)..."
hf download openai/gpt-oss-120b --exclude "original/*" "metal/*"

# Force offline mode for vLLM to prevent any unexpected download attempts during startup
export HF_HUB_OFFLINE=1

vllm serve openai/gpt-oss-120b \
    --gpu-memory-utilization 0.95 \
    --host 127.0.0.1 \
    --max-num-seqs 400 \
    --enable-chunked-prefill \
    --port 8000 \
    --max-model-len 32768 
