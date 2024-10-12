# Getting Started with [Repo Name]

This guide outlines the steps to set up a development environment for [Repo Name] using Docker and VSCode.

## Prerequisites

Ensure the following tools are installed:

- [Docker](https://docs.docker.com/get-docker/)
- (If using VSCode) [VSCode](https://code.visualstudio.com/Download) with the [Docker Extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker)

## Steps

### Run Docker

Open the docker program.

### (VSCode)

Open the repo with VSCode, and you should see a popup in the bottom right corner that says:

This will take 5-10 minutes.

Please note, it will look like it has hung whilst it builds the image for the first time, click "Show log" to see progress if you are concerned. 

### (Other editors like Vim)

Run `./.devcontainer/bootstrap.sh`

## Welcome

You are now in the developer container. You'll find the repo mounted to the 'workspace' directory (`cd workspace`). 

Changes you make in `workspace` will be reflected where you cloned the repo, however in this environment you'll have access to all our tooling at the correct version. Nothing else persists between bootstrapped sessions.