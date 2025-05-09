#!/usr/bin/env bash

set -euo pipefail

# This script uses Docker to install dependencies with unlimited memory resources
# It isolates the large WASM file handling from your local system memory

echo "Running Docker-based installation..."

# Create Docker image for installation
cat > Dockerfile.install <<EOF
FROM node:18

WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn .yarn

# Copy only necessary files for installation
COPY packages/*/package.json ./packages-temp/
RUN mkdir -p packages && \
    for dir in packages-temp/*/; do \
      pkg_dir=\$(basename "\$dir") && \
      mkdir -p "packages/\$pkg_dir" && \
      mv "packages-temp/\$pkg_dir/package.json" "packages/\$pkg_dir/"; \
    done && \
    rm -rf packages-temp

# Run yarn install
RUN yarn install

# Create a marker file to indicate completion
RUN echo "Installation completed successfully" > /app/install-success.txt
EOF

echo "Building installation Docker image..."
docker build -t duckdb-wasm-installer -f Dockerfile.install .

echo "Running installation in Docker container..."
docker run --name duckdb-wasm-installer -v $(pwd)/node_modules:/app/node_modules duckdb-wasm-installer

# Check if installation was successful
if docker cp duckdb-wasm-installer:/app/install-success.txt ./install-success.txt &> /dev/null; then
  echo "Installation completed successfully!"
  rm -f ./install-success.txt
  
  # Copy the .yarn state directory to ensure local state is up to date
  docker cp duckdb-wasm-installer:/app/.yarn/install-state.gz ./.yarn/
  
  echo "Dependencies have been installed to your local node_modules directory."
else
  echo "Installation failed in Docker container. Check logs above for errors."
  exit 1
fi

# Clean up
docker rm duckdb-wasm-installer
rm -f Dockerfile.install

echo "You can now proceed with building the project." 
