# Use the official NVIDIA CUDA 12.4 Development image
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Prevent interactive prompts during apt installations
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables for Rust
ENV CARGO_HOME=/root/.cargo
ENV RUSTUP_HOME=/root/.rustup
ENV PATH=${CARGO_HOME}/bin:${PATH}

# Install required system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    cmake \
    pkg-config \
    libssl-dev \
    clang \
    libstdc++-12-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L -O https://github.com/Kitware/CMake/releases/download/v3.29.3/cmake-3.29.3-linux-x86_64.tar.gz && \
    tar -xzvf cmake-3.29.3-linux-x86_64.tar.gz -C /usr/local --strip-components=1 && \
    rm cmake-3.29.3-linux-x86_64.tar.gz

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Set the default working directory
WORKDIR /workspace
COPY . .
