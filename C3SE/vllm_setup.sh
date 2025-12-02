#!/bin/bash

# replace the 

cd $TMPDIR




# Now run your install (target venv is also in TMPDIR)
uv venv "$TMPDIR/my_env"
source "$TMPDIR/my_env/bin/activate"
uv pip install vllm==0.9.0
