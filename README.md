# Ollama with Intel GPUs

This repository demonstrates running [Ollama](https://github.com/ollama/ollama) with [`ipex-llm`](https://github.com/intel/ipex-llm) as an accelerated backend, compatible with both Intel iGPUs and dedicated GPUs (such as Arc, Flex, and Max). The provided `docker-compose.yml` file includes a patched version of Ollama for Intel acceleration with the required parameters and settings, along with the [Open WebUI](https://docs.openwebui.com/) interface for convenience.

![Benchmark results](/readme_imgs/title.png)

Read more about the project and benchmark results in blog post: [https://nikolasent.github.io/hardware/deeplearning/2025/02/09/iGPU-Benchmark-VLM.html](https://nikolasent.github.io/hardware/deeplearning/2025/02/09/iGPU-Benchmark-VLM.html). The results were obtained with intelanalytics/ipex-llm-inference-cpp-xpu:2.2.0-SNAPSHOT base Docker image running on Debian 12 with Kernel 6.11.5.

## Quick Start

Using Intel GPUs requires that you have Intel firmware installed. For example, on Debian-like systems:

```bash
sudo apt-get install firmware-misc-nonfree firmware-intel-graphics
sudo update-initramfs -u -k all  # Required after kernel updates as well.
```

[Docker](https://docs.docker.com/engine/install/) and [docker compose](https://docs.docker.com/compose/install/) are also required.

```bash
docker compose build
docker compose up -d
```

Open [http://127.0.0.1:18080](http://127.0.0.1:18080) to access Open WebUI with accelerated ollama backend.

_Tip:_  For performance monitoring, including GPU utilization and power usage, `intel-gpu-top` is a useful tool, which is provided as part of `intel-gpu-tools` package:
```
sudo apt install intel-gpu-tools
sudo intel_gpu_top
```

Alternatively, one may compile [btop++](https://github.com/aristocratos/btop) with Intel GPU support.

## Parameters

The Docker environment is pre-configured to run on Intel iGPUs. Here are some parameters that may need adjustment:

In the [docker-compose.yml](docker-compose.yml) file:
* Configure the volumes of services to set up where data and models will be stored. Prefer using disks with fast I/O.
* Use memory limit features, such as `mem_limit: "32G"`, to limit RAM used by ipex_ollama service.
* Configure `DEVICE` variable if another hardware, such as a dedicated GPU, is used.
* Customize `OLLAMA_NUM_GPU` if required to manage GPU offload.
* Other Ollama variables can be specified in the environment section of the ipex_ollama service. For example, set `OLLAMA_NUM_CTX` to change the default model context length (it is set to be 8192 by default). Please note that some variable names are different from those used for similar purposes in the original Ollama.

## Advice on performance

1. If using CPU inference, tuning the `num_thread` model parameter in ollama for specific tasks (given the model and context length) may improve performance.
2. Use the `cpuset` option in `docker-compose.yml` to pin the `ipex_ollama` service to specific CPU cores. For example, use `cpuset: "0-3"` to utilize the first four CPU cores (e.g., to use performance cores only). Select the most performant value empirically.
3. It can be a good idea to use optimised models, for example, the models optimised by [Unsloth](https://huggingface.co/unsloth) to achieve better performance (for example, Qwen3:4b with Unsloth optimisations runs 3.8% faster on an iGPU).

## Benchmarks

The script [scripts/benchmark.py](scripts/benchmark.py) contains a benchmarking tool that evaluates tokens/s generated by any OpenAI-compatible API, including benchmarks for both Language Models (LLMs) and Vision-Language Models (VLMs). The benchmarks are reported on an Intel Ultra 5 125H Meteor Lake SoC with 64GB RAM.

With sufficient RAM, this SoC can handle relatively large models locally, making it a power-efficient solution for low-cost experiments with local models.

Feel free to explore the benchmark code and adjust it as needed for your specific experimentation and setup. The provided code is configured to produce the results below, so ensure that the required models are pulled before running the benchmark script.

The benchmark script is designed to be a standalone script that can be executed from the host machine (not from inside the Docker environment). One can use this benchmark code to test any OpenAI-compatible APIs by adjusting the API_URI and specifying the required model names.

### Language models

| Model              | Ultra 5 CPU tokens/s | Ultra 5 iGPU tokens/s | RTX 3090 tokens/s |
|--------------------|----------------------|-----------------------|-------------------|
| deepseek-r1:70b    | 1.12 ± 0.07          | 1.65 ± 0.08           | NA                |
| llama3.3:70b       | 1.16 ± 0.01          | 1.58 ± 0.00           | NA                |
| llama3.1:70b       | 1.17 ± 0.00          | 1.57 ± 0.00           | NA                |
| llama3.1:8b        | 9.76 ± 0.18          | 12.69 ± 0.20          | 104.31 ± 2.06     |
| qwen3:32b          | 3.10 ± 0.24          | 2.68 ± 0.09           | 32.90 ± 1.03      |
| qwen3:30b-a3b      | 12.83 ± 0.10         | 19.83 ± 0.54          | 121.39 ± 0.73     |
| qwen3:8b           | 11.59 ± 0.06         | 10.67 ± 0.13          | 101.30 ± 0.73     |
| qwen3:4b           | 16.49 ± 0.15         | 18.00 ± 0.39          | 127.23 ± 1.61     |
| qwen2.5:72b        | 1.11 ± 0.01          | 1.24 ± 0.00           | NA                |
| qwen2.5:32b        | 2.46 ± 0.01          | 3.44 ± 0.02           | 31.91 ± 0.34      |
| qwen2.5:7b         | 10.26 ± 0.18         | 13.06 ± 0.09          | 101.03 ± 1.01     |
| qwq                | 2.29 ± 0.08          | 3.01 ± 0.04           | 30.53 ± 0.75      |
| mistral-small:24b  | 3.37 ± 0.03          | 4.87 ± 0.02           | 45.31 ± 0.25      |
| phi4:14b           | 5.27 ± 0.08          | 7.11 ± 0.06           | 64.09 ± 0.95      |
| phi3.5:3.8b        | 19.07 ± 0.86         | 19.60 ± 2.42          | 171.51 ± 1.15     |
| llama3.2:3b        | 20.63 ± 0.44         | 23.20 ± 0.26          | 161.96 ± 3.01     |
| smallthinker:3b    | 13.83 ± 0.63         | 14.66 ± 0.42          | 105.53 ± 1.84     |
| smollm2:1.7b       | 27.41 ± 0.66         | 27.84 ± 0.65          | 209.49 ± 1.78     |
| smollm2:360m       | 57.56 ± 2.63         | 35.13 ± 0.32          | 250.60 ± 8.13     |
| starcoder2:3b      | 19.47 ± 1.51         | 22.30 ± 2.38          | 177.34 ± 3.42     |
| qwen2.5-coder:1.5b | 27.19 ± 0.26         | 36.74 ± 0.23          | 170.02 ± 4.20     |
| opencoder:1.5b     | 32.88 ± 1.60         | 17.67 ± 0.90          | 207.72 ± 3.92     |

### VLMs

| Model               | Ultra 5 iGPU tokens/s | RTX 3090 tokens/s |
|---------------------|-----------------------|-------------------|
| llama3.2-vision:90b | 0.92 ± 0.01           | NA                |
| llama3.2-vision:11b | 5.73 ± 0.03           | 61.90 ± 0.20      |
| minicpm-v:8b        | 14.94 ± 0.41          | 98.69 ± 0.18      |
| llava-phi3:3.8b     | 18.93 ± 0.12          | 154.73 ± 1.62     |
| moondream:1.8b      | 35.53 ± 1.48          | 280.98 ± 45.34    |

## Links

1. Intel docs on `ipex-llm`: [Run Ollama with IPEX-LLM on Intel GPU](https://ipex-llm-latest.readthedocs.io/en/latest/doc/LLM/Quickstart/ollama_quickstart.html).
2. [`ipex-llm` repo](https://github.com/intel/ipex-llm/tree/main).
