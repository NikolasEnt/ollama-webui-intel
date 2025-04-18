FROM ipex-llm-inference-cpp-xpu:2.2.0

RUN mkdir -p /llm/ollama \
    && cd /llm/ollama \
    && init-ollama

ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/llm/ollama"

WORKDIR /llm/ollama
