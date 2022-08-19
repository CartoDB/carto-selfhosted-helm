# Carto Dump

## Purpose

This tool is a bash script developed with the aim of collecting all the necessary information about your Carto Self Hosted deployment when opening a ticket to our support team. Attaching this information to the ticket will greatly speed up the troubleshooting process.

## How to execute Carto Dump

```bash
$ helm list
NAME            NAMESPACE       REVISION        UPDATED                                         STATUS          CHART           APP VERSION
mycarto         carto           2               2022-08-18 11:39:24.844957262 +0200 CEST        deployed        carto-1.39.14   2022.8.11-8


usage: bash carto-dump.sh [-h] --namespace NAMESPACE --release HELM_RELEASE --engine ENGINE [--gcp-project] [--extra]
mandatory arguments:
	--namespace NAMESPACE                                                    e.g. carto
	--release   HELM_RELEASE                                                 e.g. mycarto
	--engine    ENGINE                                                       specify your kubernetes cluster engine, e.g. gke, aks, eks or custo
optional arguments:
	--extra                                                                  download all cluster info, this option need to run containers in your kubernetes cluster to obtain extra checks
	--gcp-project                                                            in case of GKE engine, specify your GCP project in which Kubernetes is deployed
	-h, --help                                                               show this help message and exit
```

- Default diagnostic: It will download the basic information about your Carto environment and Kubernetes cluster (pods, deployments, services, endpoints, ingress, backend and frontend configs, events, pvc and secrets info without sensitive data).

  Example: `bash carto-dump.sh --namespace carto --release carto --engine gke`

- Default with GCP Ingress Check: It will check also the certificate installed in the Ingress resource.

  Example: `bash carto-dump.sh --namespace carto --release carto --engine gke --gcp-project example-project`

- Advanced diagnostic: It will review also the Carto API health checks, postgresql and redis conectivity and generate a cluster-info dump. 

  :warning: Note that we need to deploy some containers in the Carto namespace to check the conectivity and health checks.

  Example: `bash carto-dump.sh --namespace carto --release carto --engine gke --extra`
```
