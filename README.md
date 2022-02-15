# Helm chart and Docker compose for Carto 3

This repository contains the Helm chart files for Carto 3, ready to launch on Kubernetes using [Kubernetes Helm](https://github.com/helm/helm).

## Before you begin

### Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0
- PV provisioner support in the underlying infrastructure

### Setup a Kubernetes Cluster

For setting up Kubernetes on other cloud platforms or bare-metal servers refer to the Kubernetes [getting started guide](http://kubernetes.io/docs/getting-started-guides/).

### Install Docker

Docker is an open source containerization technology for building and containerizing your applications.

To install Docker, refer to the [Docker install guide](https://docs.docker.com/engine/install/).

### Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.

### Deploy CARTO in a self hosted environment

+ Firstly, you need a package with two files:
  - customer.env
  - key.json

+ Add your Carto Self Hosted version inside `carto3-helm/chart/values.yaml` in `selfHostedVersion` param.

+ Set your vars in `carto3-helm/chart/values.yaml` file.
  At least, the following variables must be replaced, you can find them in `customer.env` file:

  - selfHostedDomain
  - SELFHOSTED_TENANT_ID
  - CARTO_AUTH0_CLIENT_ID
  - CARTO_AUTH0_CUSTOM_DOMAIN
  - ACC_DOMAIN
  - ACC_GCP_PROJECT_ID
  - ACC_GCP_PROJECT_REGION
  - CARTO_SELFHOSTED_CARTO_DW_LOCATION
  - ENCRYPTION_SECRET_KEY

  Then, replace your postgresql passwords:

    ```bash
    postgresql:
      enabled: true
      ## @param postgresql.image.tag Tag of the PostgreSQL image
      ##
      image:
        tag: "13.5.0-debian-10-r84"
      auth:
        username: carto
        password: "*********"
        database: workspace_db
        postgresPassword: "***********"
    ```

  Now, create a secret in your k8s cluster for the Google Service Account.
  Note that the `key.json` file is the same that you can find in the package:

  `kubectl create secret generic selfhosted-google-serviceaccount --from-file=key.json --namespace=<namespace>`

  Add the secret ref in `carto3-helm/chart/values.yaml` in `existingSecret` param:

    ```bash
    google:
    ## @param google.credentialFile Content of the Google Credential file
    ##
    credentialFile: ""
  
    ## @param google.existingSecret.name Secret containing the Google Credential file
    ## @param google.existingSecret.key Key name of the Google Credential file inside the secret
    ##
    existingSecret:
      name: "selfhosted-google-serviceaccount"
      key: "key.json"
    ```

+ Install dependencies:
  `helm dependency build`

+ Deploy Carto in your namespace:

  `kubectl config set-context --current --namespace=<namespace>`

  `helm install carto3-selfhosted . --values ./values.yaml`

+ Add the Load Balancer IP to your DNS with your Domain:

  `kubectl get svc carto3-selfhosted-router -o jsonpath='{.status.loadBalancer.ingress.*.ip}'`

+ If you need to replace one variable now, you can modify it in `values.yaml` file and then run the following command:

  `helm upgrade carto3-selfhosted . --values=./values.yaml`