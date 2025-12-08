apt update
apt install -y python3.12-dev
apt install python3.12-venv
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv 
source .venv/bin/activate
uv pip install ipykernel openai nltk dotenv polars pydantic faiss-cpu numpy openai  gdown
deactivate

uv venv vllm_env
source vllm_env/bin/activate
uv pip install vllm
deactivate

git clone https://github.com/BjornWest/ClaimsMCP.git
git config --global user.name "BjornWest"
git config --global user.email "bpf.westerlund@gmail.com"
cd ClaimsMCP
git remote set-url origin https://BjornWest@github.com/BjornWest/ClaimsMCP.git
cd ..
git clone https://BjornWest@github.com/swartling/Data-Analysis-Project-28