apt update
apt install -y python3.12-dev
apt install -y python3.12-venv
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$PATH:/root/.local/bin"
uv venv 
source .venv/bin/activate
uv pip install ipykernel openai nltk dotenv polars pydantic faiss-cpu numpy openai  gdown scikit-learn
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


curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz