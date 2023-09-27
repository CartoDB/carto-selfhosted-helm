### Access to CARTO from outside the cluster

The entry point to the CARTO Self Hosted is through the `router` Service. By default, it is configured in `ClusterIP` mode. That means it's only usable from inside the cluster. If you want to connect to your deployment with this mode, you need to use
[kubectl port-forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).
But this only makes it accessible to your machine.

**Requirements when exposing the service:**

- CARTO only works with HTTPS. TLS termination can be done in the CARTO application level (Router component), or in a load balancer that gets the request before sending it back to the application.
- The connection timeout of all incoming connections must be at least `605` seconds.
- Configure a domain pointing to the exposed service.

**We recommend two ways to make your Carto application accessible from outside the Kubernetes network:**

- `LoadBalancer` mode in Carto Router Service

  This is the easiest way to open your CARTO Self Hosted to the world on cloud providers which support external load balancers. You need to change the `router` Service type to `LoadBalancer`. This provides an externally-accessible IP address that sends traffic to the correct component on your cluster nodes.

  The actual creation of the load balancer happens asynchronously, and information about the provisioned balancer is published in the Service's `.status.loadBalancer` field.

- Expose your Carto Application with an `Ingress` (**This is currently supported only for GKE**).

  Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource, you can find more documentation [here](https://kubernetes.io/docs/concepts/services-networking/ingress/).

  Within this option you could either use your own TLS certificates, or GCP SSL Managed Certificates.

  > :warning: if you are running a GKE cluster 1.17.6-gke.7 version or lower, please check [Cluster IP configuration](#troubleshooting)

  **Useful links**

  - [google-managed-certs](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs#caa)
  - [creating_an_ingress_with_a_google-managed_certificate](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs#creating_an_ingress_with_a_google-managed_certificate)

#### Expose CARTO with the Carto Router service in `LoadBalancer` mode

You can find an example [here](service_loadBalancer/config.yaml). Also, we have prepared a few specifics for different Kubernetes flavors, just add the config that you need in your `customizations.yaml`:

- [AWS EKS](service_loadBalancer/aws_eks/config.yaml)
- [AWS EKS](service_loadBalancer/aws_eks_tls_offloading/config.yaml) Note you need to [import your certificate in AWS ACM](https://docs.aws.amazon.com/acm/latest/userguide/import-certificate.html)
- [GCP GKE](service_loadBalancer/config.yaml)
- [AZU AKS](service_loadBalancer/azu_aks/config.yaml)

> Note that with this config a [Load Balancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer) resource is going to be created in your cloud provider, you can find more documentation about this kind of service [here](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)

#### Expose CARTO with Ingress and your own TLS certificates

- [GKE Ingress example config for CARTO with custom certificates](ingress/gke/custom_cert_config.yaml)

  > :point_right: Note that you need to create the TLS secret certificate in your kubernetes cluster, you could use the following command to create it

  ```bash
  kubectl create secret tls -n <namespace> carto-tls-cert --cert=cert.crt --key=cert.key
  ```

  > :warning: The certificate created in the kubernetes tls secret should also have the chain certificates complete. If your certificate has been signed by a intermediate CA, this issuer has to be included in your ingress certificate.

#### Expose CARTO with Ingress and GCP SSL Managed Certificates

- [GKE Ingress example config for CARTO with GCP Managed Certificates](ingress/gke/gcp_managed_cert_config.yaml)

  You can configure your Ingress controller to use [Google Managed Certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs) on the load balancer side.

  > :warning: The certificate and LB can take several minutes to be configured, so be patient

  **Prerequisites**

  - You must own the domain for the Ingress (the one defined at `appConfigValues.selfHostedDomain`)
  - You must have created your own [Reserved static external IP address](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
  - You must create an A DNS record that relates your domain to the just created static external IP address
  - Check also [this requirements](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs#prerequisites)

  :point_right: You can easily create a static external IP address with

  ```bash
  gcloud compute addresses create my_carto_ip --global
  ```

#### Create a SSL Policy for your Ingress

To define an SSL policy, you specify a minimum TLS version and a profile. The profile selects a set of SSL features in the Ingress Load Balancer.

Please see the [Google Documentacion](https://cloud.google.com/load-balancing/docs/ssl-policies-concepts#defining_an_ssl_policy) in order to select your best profile

1. In the same project that you have your ingress load balancer, create a profile that meets your requirements

```bash
gcloud compute ssl-policies create my-ssl-policy --min-tls-version=1.2 --profile=MODERN --project=<gcp-project>
```

2. Attach the ssl policy to your Ingress frontend configuration

```diff
  apiVersion: networking.gke.io/v1beta1
  kind: FrontendConfig
  spec:
+    sslPolicy: my-ssl-policy
```

3. [Update your helm installation](https://github.com/CartoDB/carto-selfhosted-helm#update)

**Troubleshooting**

Please see our [troubleshooting](#troubleshooting) section if you have problems with your ingress resource.