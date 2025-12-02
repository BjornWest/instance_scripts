#!/bin/bash

uv venv "$TMPDIR/vllm_env"
source "$TMPDIR/vllm_env/bin/activate"
uv pip install vllm==0.9.0
