# Tools
## Carto Support Tool

### Purpose

This tool is a bash script developed with the aim of collecting all the necessary information about your Carto Self Hosted deployment when opening a ticket to our support team. Attaching this information to the ticket will greatly speed up the troubleshooting process.
**NOTE**: this tool is not gathering any senstive information, like secrets content.

### Requirements

- Before executing the script from your terminal, ensure that `kubectl` commands are working on your cluster. For instance, `kubectl --namespace carto get pods`.
- If you are using `GKE`, please make sure that your terminal has access to `gloud` commands (`gcloud auth login`) and you've set the `--gcp-project` flag in the `carto-support-tool.sh`. This way, we will collect information about the deployment of google managed services like LoadBalancer, certificates ... etc.
- It is **recommended** to run it using the `--extra` flag, because it will help CARTO Support team to provide a better diagnostic.

### How to execute Carto Dump

```bash
$ helm list
NAME            NAMESPACE       REVISION        UPDATED                                         STATUS          CHART           APP VERSION
mycarto         carto           2               2022-08-18 11:39:24.844957262 +0200 CEST        deployed        carto-1.39.14   2022.8.11-8


usage: bash carto-support-tool.sh [-h] --namespace NAMESPACE --release HELM_RELEASE --engine ENGINE [--gcp-project] [--extra]
mandatory arguments:
    --namespace NAMESPACE                                                    e.g. carto
    --release   HELM_RELEASE                                                 e.g. mycarto
    --engine    ENGINE                                                       specify your kubernetes cluster engine, e.g. gke, aks, eks or custom

optional arguments:
    --extra                                                                  download all cluster info, this option need to run containers in your kubernetes cluster to obtain extra checks
    --gcp-project                                                            in case of GKE engine, specify your GCP project in which Kubernetes is deployed
    -h, --help                                                               show this help message and exit
```

- **Default diagnostic**: It will download the basic information about your Carto environment and Kubernetes cluster (pods, deployments, services, endpoints, ingress, backend and frontend configs, events, pvc and secrets info without sensitive data).

  Example: `bash carto-support-tool.sh --namespace carto --release carto --engine gke`

- **Default with GCP Ingress Check**: It will check also the certificate installed in the Ingress resource.

  Example: `bash carto-support-tool.sh --namespace carto --release carto --engine gke --gcp-project example-project`

- **Advanced diagnostic**: It will review also the Carto API health checks, postgresql and redis conectivity and generate a cluster-info dump.

  :warning: Note that we need to deploy some containers in the Carto namespace to check the conectivity and health checks.

  Example: `bash carto-support-tool.sh --namespace carto --release carto --engine gke --extra`


## Download customer package tool

### Description

This tool can be used to download a newer version of the Carto selfhosted customer package, allowing customers to update an existing installation to the Carto selfhosted latest release without having to contact support to provide the files.

### Pre-requisites

- Customer package files (`carto-values.yaml` and `carto-secrets.yaml`) used for the existing installation.
- Linux machine with bash terminal.
- Packages installed: `yq`, `jq` and `gcloud`.

### How to download the latest customer package

1. Run the script passing the following arguments:
   - `-d | --dir` Directory containing the existing `carto-values.yaml` and `carto-secrets.yaml` files.
   - `-s | --selfhosted-mode` Carto selfhosted installation mode. Use `k8s`.

   ```bash
   $ ./carto-download-customer-package.sh -d /tmp/carto -s k8s
   Activated service account credentials for: [serv-onp-xxx@carto-tnt-onp-xxx.iam.gserviceaccount.com]
   Copying gs://carto-tnt-onp-xxx-client-storage/customer-package/carto-selfhosted-k8s-customer-package-xxx-2022-10-18.zip...
   / [1 files][  3.5 KiB/  3.5 KiB]                                                
   Operation completed over 1 objects/3.5 KiB.                                      
   ```

2. Unzip your customer package files and use them to update your Carto selfhosted installation.
