# GKE Autopilot

Autopilot is a new mode of operation for creating and managing Kubernetes clusters in Google Kubernetes Engine (GKE). In this mode, GKE configures and manages the underlying infrastructure, including nodes and node pools enabling users to only focus on the target workloads and pay per pod resource requests (CPU, memory, and ephemeral storage).

Please review the official documentation:

[Autopilot Overview](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)

[Autopilot Architecture](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-architecture)

[Autopilot Private Cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept)

There are some recommendations and tips to deploy Carto in a GKE Autopilot Cluster:

## Security

For security reasons, it is advisable to create the cluster in private mode. Private clusters use nodes that do not have external IP addresses. This means that clients on the internet cannot connect to the IP addresses of the nodes.

[The control plane](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept#the_control_plane_in_private_clusters) runs on a virtual machine (VM) that is in a VPC network in a Google-owned project. In private clusters, the control plane's VPC network is connected to your cluster's VPC network with [VPC Network Peering](https://cloud.google.com/vpc/docs/vpc-peering). Your VPC network contains the cluster nodes, and the Google-owned Google Cloud VPC network contains your cluster's control plane. Traffic between nodes and the control plane is routed entirely using internal IP addresses.

## Networking

As we commented above, in a private cluster the workers nodes will be created in the customer VPC, so Autopilot needs a subnet to be deployed. We could see an example of the subnet creation [here](#terraform-examples), please set a network mask big enough to deploy all services without problems, at least it should be `/20`.

Another two secondary IP ranges will be created inside this subnet, one for pods and another for kubernetes services.

- Cluster default pod address range: All pods in the cluster are assigned an IP address from this range. Enter a range (in CIDR notation) within a network range, a mask, or leave this field blank to use a default range. We recommend at least a `/21` mask for pods

- Service address range: Cluster services will be assigned an IP address from this IP address range. Enter a range (in CIDR notation) within a network range, a mask, or leave this field blank to use a default range. We recommend at least a `/24` mask for services


## Workload Identity

### What is Workload Identity?
Applications running on GKE might need access to Google Cloud APIs such as Compute Engine API, BigQuery Storage API, or Machine Learning APIs.

Workload Identity allows a Kubernetes service account in your GKE cluster to act as an IAM service account. Pods that use the configured Kubernetes service account automatically authenticate as the IAM service account when accessing Google Cloud APIs. Using Workload Identity allows you to assign distinct, fine-grained identities and authorization for each application in your cluster.

### How Workload Identity works
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

### How to enable Carto to use Workload Identity:

- Create an IAM service account for your application or use an existing IAM service account instead.

  You can use this command:

  `gcloud iam service-accounts create <IAM_SERVICE_ACCOUNT_NAME> --project=<GCP_PROJECT_ID>`

- Send the Service Account Email to Carto Support Team [support@carto.com](mailto:support@carto.com). We will ensure that your Service Account is granted the required roles to run CARTO Self Hosted (remember you cannot change the Service Account without contacting support).

- Then, allow the Kubernetes service account that is going to be created in your GKE cluster to impersonate the IAM service account by adding an IAM policy binding between the two service accounts. This binding allows the Kubernetes service account to act as the IAM service account.

  ```bash
  gcloud iam service-accounts add-iam-policy-binding <IAM_SERVICE_ACCOUNT_EMAIL> \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:<PROJECT_ID>.svc.id.goog[<KUBERNETES_NAMESPACE>/carto-workload-identity]"
  ```

- Add the following lines to your `customizations.yaml`:

```yaml
workloadIdentityConfig:
  enableWorkloadIdentity: "true"
  workloadIdentitySaEmail: "<IAM_SERVICE_ACCOUNT_EMAIL>"
```

## Troubleshooting

- :warning: `No nodes available to schedule pods` or `All cluster resources were brought up, but: only 0 nodes out of 2 have registered; cluster may be unhealthy.`

  Ensure that the default Compute Engine service account (<PROJECT_NUMBER>-compute@developer.gserviceaccount.com) is not disabled.
  
  Run the following command to check that disabled field is not set to true
  
  `gcloud iam service-accounts describe <PROJECT_NUMBER>-compute@developer.gserviceaccount.com`

<!--
TODO: Add more things related to Troubleshooting
-->

## Terraform Examples

From Carto, we have developed some terraform examples to deploy a private GKE Autopilot cluster.

[Example terraform code for Autopilot](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/gcp/gke-autopilot.tf)
