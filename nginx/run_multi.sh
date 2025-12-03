source vllm_env/bin/activate
python3 /instance_scripts/nginx/multi_instance.py --model "openai/gpt-oss-20b" \
    --replicas 2 \
    --gpu-util 0.90 \
    --max-seqs 256