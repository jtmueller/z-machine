# Use an official Ubuntu as a parent image
FROM ubuntu:latest


ENV ZIG_VERSION 0.10.0
ENV DEBIAN_FRONTEND=noninteractive

# Main dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Zig
RUN curl -LO https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz && \
    tar xf zig-linux-x86_64-${ZIG_VERSION}.tar.xz && \
    mv zig-linux-x86_64-${ZIG_VERSION} /opt/zig && \
    ln -s /opt/zig/zig /usr/local/bin/zig && \
    rm zig-linux-x86_64-${ZIG_VERSION}.tar.xz

# Create a working directory
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Set the default entrypoint to start a shell
ENTRYPOINT ["/bin/bash"]
