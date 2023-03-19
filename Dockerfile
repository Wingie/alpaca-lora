FROM nvidia/cuda:11.7.0-devel-ubuntu20.04
# ARG DEBIAN_FRONTEND=noninteractive
# Update apt-get and install some required packages

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get install -y software-properties-common gcc && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update -y && apt-get install -y \
    git \
    wget \
    build-essential \
    nvidia-cuda-toolkit \
    python3.8 \
    python3.8-dev \
    python3-pip \
    python3.8-distutils \
 && rm -rf /var/lib/apt/lists

# Install and setup Conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    /opt/conda/bin/conda clean -ya
ENV PATH="/opt/conda/bin:${PATH}"
RUN conda create -n alpaca-lora python=3.7 -y && \
    echo "conda activate alpaca-lora" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]
RUN conda init

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1 && \
    update-alternatives --set python3 /usr/bin/python3.8
RUN pip3 install --upgrade pip
RUN git clone https://github.com/oobabooga/text-generation-webui.git \
 && cd text-generation-webui \
 && pip install -r requirements.txt \
 && pip install --upgrade fsspec

RUN git clone https://github.com/qwopqwop200/GPTQ-for-LLaMa.git \
 && cd GPTQ-for-LLaMa \
 && pip install -r requirements.txt \
 && python3 setup_cuda.py install

WORKDIR /text-generation-webui
RUN python3 download-model.py --text-only decapoda-research/llama-7b-hf
COPY llama-7b-4bit.pt /text-generation-webui/models/

conda activate textgen
conda install torchvision=0.14.1 torchaudio=0.13.1 pytorch-cuda=11.7 git -c pytorch -c nvidia
python3 -m venv venv
source $HOME/venv/bin/activate
CMD ["python", "server.py", "--load-in-4bit", "--model", "llama-7b-hf", "--listen"]