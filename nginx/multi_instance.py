import argparse
import subprocess
import sys
import math

# Configuration
NGINX_CONFIG_PATH = "/etc/nginx/sites-enabled/vllm_lb"
PYTHON_INTERPRETER = sys.executable  # Uses the current venv python

def run_command(cmd, shell=False):
    """Runs a shell command."""
    try:
        subprocess.check_call(cmd, shell=shell)
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {cmd}")
        sys.exit(1)

def generate_nginx_config(ports):
    """Creates the Nginx config file dynamically."""
    upstream_servers = "\n    ".join([f"server 127.0.0.1:{p};" for p in ports])
    
    config = f"""
upstream vllm_backend {{
    least_conn;
    {upstream_servers}
}}

server {{
    listen 80;
    location / {{
        proxy_pass http://vllm_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_buffering off;
        proxy_read_timeout 1200s;
    }}
}}
"""
    # Write to temp file then move (requires sudo)
    with open("vllm_lb.tmp", "w") as f:
        f.write(config)
    
    run_command(f"sudo mv vllm_lb.tmp {NGINX_CONFIG_PATH}", shell=True)
    run_command("sudo systemctl reload nginx", shell=True)
    print(f"✅ Nginx reloaded with {len(ports)} workers.")

def main():
    parser = argparse.ArgumentParser(description="Auto-launch vLLM cluster")
    parser.add_argument("--model", type=str, required=True, help="HuggingFace model name")
    parser.add_argument("--replicas", type=int, default=2, help="Number of server instances")
    parser.add_argument("--gpu-util", type=float, default=0.90, help="Total GPU memory fraction to use (0.90 = 90%)")
    parser.add_argument("--max-seqs", type=int, default=256, help="Max sequences per instance")
    args = parser.parse_args()

    # 1. Calculate Memory per Instance
    mem_per_instance = args.gpu_util / args.replicas
    # Round down to 2 decimal places to be safe
    mem_per_instance = math.floor(mem_per_instance * 100) / 100.0
    
    print(f"Launching {args.replicas} instances of {args.model}")
    print(f"Memory per instance: {mem_per_instance} (Total: {args.gpu_util})")

    # 2. Kill old processes (using PM2)
    print("🧹 Cleaning up old processes...")
    subprocess.run("pm2 delete all", shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)

    # 3. Launch new instances
    ports = []
    base_port = 8000
    
    for i in range(args.replicas):
        port = base_port + i
        ports.append(port)
        
        name = f"vllm-{i}"
        cmd = (
            f"pm2 start {PYTHON_INTERPRETER} --name {name} -- "
            f"-m vllm.entrypoints.openai.api_server "
            f"--model {args.model} "
            f"--port {port} "
            f"--gpu-memory-utilization {mem_per_instance} "
            f"--max-num-seqs {args.max_seqs} "
            f"--enable-chunked-prefill"
        )
        
        print(f"Starting worker {i} on port {port}...")
        run_command(cmd, shell=True)

    # 4. Update Nginx
    generate_nginx_config(ports)
    print("\n Cluster Ready! Dashboard: 'pm2 monit'")

if __name__ == "__main__":
    main()