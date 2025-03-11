FROM elixir:1.15-slim

LABEL maintainer="Instruktor Team"
LABEL description="Docker image for Instruktor - web automation and data extraction toolkit"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV MIX_ENV=prod

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    build-essential \
    cmake \
    gnupg \
    lsb-release \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright dependencies
RUN apt-get update && apt-get install -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxcb1 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Copy project files
COPY . .

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install Elixir dependencies
RUN mix deps.get && \
    mix compile

# Set up Python environment
RUN cd priv/python && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install -r requirements.txt && \
    python3 -m playwright install chromium

# Make scripts executable
RUN chmod +x scripts/*.sh instruktor

# Create a directory for Llama models
RUN mkdir -p /app/models

# Expose ports
EXPOSE 8090
EXPOSE 8765
EXPOSE 4000

# Set entrypoint
ENTRYPOINT ["/app/instruktor"]
CMD ["help"] 