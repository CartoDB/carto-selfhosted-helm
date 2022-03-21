## Autoscaling
It is recommended to enable autoscaling in your installation, which will allow scaling based on the resources consumption needs of your cluster.

This feature is based on [Kubernetes Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) functionality.

### Prerequisites

To enable the autoscaling feature, you need to use a cluster that has a [Metrics Server](https://github.com/kubernetes-sigs/metrics-server#readme) deployed and configured. The Kubernetes Metrics Server collects resource metrics from the kubelets in your cluster, and exposes those metrics through the [Kubernetes API](https://kubernetes.io/docs/concepts/overview/kubernetes-api/), using an [APIService](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/) to add new kinds of resource that represent metric readings.

To learn how to deploy the Metrics Server, see the [metrics-server installation guide](https://github.com/kubernetes-sigs/metrics-server#installation).

By default, some managed cluster such as GKE have installed the metric server in latest versions, for other cases, you can follow these steps.

Installation Example:

- Default:
  ```bash
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  ```

- High Availability:
  ```bash
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability.yaml
  ```

### Enable Carto autoscaling feature

You can find an autoscaling config file example in `customizations/autoscaling/config.yaml`, it is only necessary add this file in the `install` or `upgrade` command and start to use the autoscaling feature.

  ```bash
  helm install \
    <your_own_installation_name|carto> \
    carto-selfhosted/carto \
    --namespace <your_namespace> \
    -f carto-values.yaml \
    -f carto-secrets.yaml \
    -f customizations/autoscaling/config.yaml \
    <other_custom_files>
  ```

Also you can set your own preferences using the minimum and maximum values that you need in this file.
