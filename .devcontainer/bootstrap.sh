#!/bin/bash

# Get the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
IMAGE_NAME="silicon-dev-env"
IMAGE_VERSION="1.0"

# Build the Docker image
echo "Building Docker image ${IMAGE_NAME}:${IMAGE_VERSION}..."
if ! docker build -t "${IMAGE_NAME}:${IMAGE_VERSION}" "${SCRIPT_DIR}"; then
    echo "Docker build failed. Please check your Dockerfile and environment."
    exit 1
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed or not in PATH."
    exit 1
fi

# Check if the user is part of the docker group or if sudo is needed
if ! docker info &> /dev/null; then
    echo "You might need to run this script with sudo or check Docker permissions."
    SUDO="sudo"
else
    SUDO=""
fi

# Run the Docker container with the absolute path of the script's directory mounted
echo "Running the Docker container..."
${SUDO} docker run -it --rm -v "${SCRIPT_DIR}:/workspace" "${IMAGE_NAME}:${IMAGE_VERSION}" /bin/bash
