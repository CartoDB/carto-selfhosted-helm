# Helm chart and Docker compose for Carto 3

This repository contains the Helm chart files for Carto 3, ready to launch on Kubernetes using [Kubernetes Helm](https://github.com/helm/helm).

## Before you begin

### Prerequisites
- Kubernetes 1.21.2
- Docker 20.10.8
- Helm 3.6.3

### Setup a Kubernetes Cluster

For setting up Kubernetes on other cloud platforms or bare-metal servers refer to the Kubernetes [getting started guide](http://kubernetes.io/docs/getting-started-guides/).

### Install Docker

Docker is an open source containerization technology for building and containerizing your applications.

To install Docker, refer to the [Docker install guide](https://docs.docker.com/engine/install/).

### Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.