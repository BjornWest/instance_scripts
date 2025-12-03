apt update
apt install -y python3.12-dev
apt install python3.12-venv
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$PATH:/root/.local/bin"

uv venv venv


uv venv vllm_env
source vllm_env/bin/activate
uv pip install vllm ray[serve] 
deactivate

git clone https://github.com/BjornWest/IR_project
git config --global user.name "BjornWest"
git config --global user.email "bpf.westerlund@gmail.com"
source venv/bin/activate
uv pip install pip ipykernel openai nltk numpy rank-bm25 spacy pyserini
python3 -m spacy download en_core_web_sm
python3 -c "import nltk; nltk.download('punkt_tab', quiet=True)"


cd IR_project
git remote set-url origin https://BjornWest@github.com/BjornWest/IR_project.git



# might not need
apt install -y openjdk-21-jdk

apt install nginx


# 1. Install Nginx (if not already installed)
if ! command -v nginx &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y nginx
fi
