source vllm_env/bin/activate
uv pip install vllm ray[serve] 

# 1. Download Grafana
wget https://dl.grafana.com/oss/release/grafana-10.4.0.linux-amd64.tar.gz
tar -zxvf grafana-10.4.0.linux-amd64.tar.gz
cd grafana-v10.4.0


ray start --head
ray metrics launch-prometheus
./bin/grafana-server --config /tmp/ray/session_latest/metrics/grafana/grafana.ini web
