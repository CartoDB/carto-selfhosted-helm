# Workload Identity

## What is Workload Identity?
Applications running on GKE might need access to Google Cloud APIs such as Compute Engine API, BigQuery Storage API, or Machine Learning APIs.

Workload Identity allows a Kubernetes service account in your GKE cluster to act as an IAM service account. Pods that use the configured Kubernetes service account automatically authenticate as the IAM service account when accessing Google Cloud APIs. Using Workload Identity allows you to assign distinct, fine-grained identities and authorization for each application in your cluster.

## How Workload Identity works
When you enable Workload Identity on a cluster, GKE automatically creates a fixed workload identity pool for the cluster's Google Cloud project. A workload identity pool allows IAM to understand and trust Kubernetes service account credentials. The workload identity pool has the following format:

`PROJECT_ID.svc.id.goog`

GKE uses this pool for all clusters in the project that use Workload Identity.

When you configure a Kubernetes service account in a namespace to use Workload Identity, IAM authenticates the credentials using the following member name:

`serviceAccount:PROJECT_ID.svc.id.goog[KUBERNETES_NAMESPACE/KUBERNETES_SERVICE_ACCOUNT]`

In this member name:

- PROJECT_ID: your Google Cloud project ID.
- KUBERNETES_NAMESPACE: the namespace of the Kubernetes service account.
- KUBERNETES_SERVICE_ACCOUNT: the name of the Kubernetes service account making the request.

The process of configuring Workload Identity includes using an IAM policy binding to bind the Kubernetes service account member name to an IAM service account that has the permissions your workloads need. Any Google Cloud API calls from workloads that use this Kubernetes service account are authenticated as the bound IAM service account.

## How to enable Carto to use Workload Identity

- Create an IAM service account for your application or use an existing IAM service account instead.

  You can use this command:

  ```bash
  gcloud iam service-accounts create <IAM_SERVICE_ACCOUNT_NAME> --project=<GCP_PROJECT_ID>
  ```

  This SA needs the `roles/iam.serviceAccountTokenCreator` role for sign URLs, you can grant it with this command:

  ```bash
  gcloud iam service-accounts add-iam-policy-binding \
    <IAM_SERVICE_ACCOUNT_EMAIL> \
    --member=serviceAccount:<IAM_SERVICE_ACCOUNT_EMAIL> \
    --role=roles/iam.serviceAccountTokenCreator
  ```

  Also see our terraform examples for [iam service accounts](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/gcp/gke-autopilot.tf)

- Send the Service Account Email to Carto Support Team [support@carto.com](mailto:support@carto.com). We will ensure that your Service Account is granted the required roles to run CARTO Self Hosted (remember you cannot change the Service Account without contacting support).

- Add the following lines to your `customizations.yaml`:

  ```yaml
  commonBackendServiceAccount:
    enableGCPWorkloadIdentity: true
    annotations:
      iam.gke.io/gcp-service-account: "<IAM_SERVICE_ACCOUNT_EMAIL>"
  ```

> :warning: The chart gives the possibility of disable commonBackendServiceAccount account creation with `commonBackendServiceAccount.create: false` but this is not compatible with  `enableGCPWorkloadIdentity: true`

- Install Carto Self Hosted Helm Chart, please see the [installations steps](../../README.md#installation-steps)

- Then, allow the Kubernetes service account that is going to be created in your GKE cluster to impersonate the IAM service account by adding an IAM policy binding between the two service accounts. This binding allows the Kubernetes service account to act as the IAM service account.

  ```bash
  gcloud iam service-accounts add-iam-policy-binding <IAM_SERVICE_ACCOUNT_EMAIL> \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:<PROJECT_ID>.svc.id.goog[<KUBERNETES_NAMESPACE>/<KUBERNETES_SERVICE_ACCOUNT>]"
  ```

  Also see our terraform example for [iam policy binding](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/gcp/gke-autopilot.tf)

  > You can find the `gcloud` command with the `KUBERNETES_NAMESPACE` and `KUBERNETES_SERVICE_ACCOUNT` values in the helm output notes once you execute the `helm install...`
