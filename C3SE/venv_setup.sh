cd $TMPDIR

python -m venv temp
source .venv/bin/activate
curl -LsSf https://astral.sh/uv/install.sh | sh

# Assuming $TMPDIR is your cluster's fast temporary space
export UV_CACHE_DIR="$TMPDIR/uv_cache"

# Ensure the directory exists
mkdir -p "$UV_CACHE_DIR"


uv pip install pydantic openai nltk


source ~/.venv/bin/activate

# get the site-packages directory
site_packages=$(python -c "import site; print(site.getsitepackages()[0])")

# replace the external_libs.pth with new temp dir
echo "${TMPDIR}/temp/lib64/python3.11/site-packages" > ${site_packages}/external_libs.pth