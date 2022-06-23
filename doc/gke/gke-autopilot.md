# GKE Autopilot

Autopilot is a new mode of operation for creating and managing Kubernetes clusters in Google Kubernetes Engine (GKE). In this mode, GKE configures and manages the underlying infrastructure, including nodes and node-pools enabling users to only focus on the target workloads and pay per pod resource requests (CPU, memory, and ephemeral storage).

Please review the official documentation:

[Autopilot Overview](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)

[Autopilot Architecture](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-architecture)

[Autopilot Private Cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept)

There are some recommendations and tips to deploy Carto in a GKE Autopilot Cluster:

## Security

For security reasons, it is advisable to create the cluster in private mode. Private clusters use nodes that do not have external IP addresses. This means that clients on the internet cannot connect to the IP addresses of the nodes.

[The control plane](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept#the_control_plane_in_private_clusters) runs on a virtual machine (VM) that is in a VPC network in a Google-owned project.

In private clusters, the control plane's VPC network is connected to your cluster's VPC network with [VPC Network Peering](https://cloud.google.com/vpc/docs/vpc-peering). Your VPC network contains the cluster nodes, and the Google-owned Google Cloud VPC network contains your cluster's control plane. Traffic between nodes and the control plane is routed entirely using internal IP addresses.

## Networking

As we commented above, in a private cluster the worker nodes will be created in the customer VPC, so Autopilot needs a subnet to be deployed. We could see an example of the subnet creation [here](#terraform-examples), please set a network mask big enough to deploy all services without problems, at least it should be `/20`.

Another two secondary IP ranges will be created inside this subnet, one for pods and another for kubernetes services.

- Cluster default pod address range: All pods in the cluster are assigned with an IP address from this range. Enter a range (in CIDR notation) within a network range, a mask, or leave this field blank to use a default range. We recommend at least a `/21` mask for pods

- Service address range: Cluster services will be assigned an IP address from this IP address range. Enter a range (in CIDR notation) within a network range, a mask, or leave this field blank to use a default range. We recommend at least a `/24` mask for services


## Workload Identity

For Workload Identity documentation, please see this [link](gke-workload-identity.md)

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
