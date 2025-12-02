apt update
apt install -y python3.12-dev
apt install python3.12-venv
curl -LsSf https://astral.sh/uv/install.sh | sh

uv venv
source venv/bin/activate


uv venv vllm_env
source vllm_env/bin/activate
uv pip install vllm
deactivate

git clone https://github.com/BjornWest/IR_project
git config --global user.name "BjornWest"
git config --global user.email "bpf.westerlund@gmail.com"
git remote set-url origin https://BjornWest@github.com/BjornWest/IR_project.git
source venv/bin/activate
uv pip install ipykernel openai nltk numpy rank-bm25 spacy pyserini
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

sudo cp "actually_important/nginx_vllm.conf" /etc/nginx/sites-available/vllm_lb

# 3. Enable the Configuration
# Remove default to avoid conflicts on port 80
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi


sudo ln -sf /etc/nginx/sites-available/vllm_lb /etc/nginx/sites-enabled/

# 4. Test and reload nginx configuration
sudo nginx -t && sudo nginx -s reload