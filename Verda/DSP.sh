apt update
apt install -y python3.12-dev
apt install python3.12-venv
python3 -m venv venv
source venv/bin/activate
curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
python3 /tmp/get-pip.py 
curl -LsSf https://astral.sh/uv/install.sh | sh

python3 -m venv vllm_env
source vllm_env/bin/activate
uv pip install vllm
deactivate

git clone https://github.com/BjornWest/ClaimsMCP.git
git config --global user.name "BjornWest"
git config --global user.email "bpf.westerlund@gmail.com"
source venv/bin/activate
uv pip install ipykernel openai nltk dotenv polars