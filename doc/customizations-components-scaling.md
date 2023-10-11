## Components scaling

### Autoscaling

It is recommended to enable autoscaling in your installation. This will allow the cluster to adapt dynamically to the needs of the service
and maximize the use of the resources of your cluster.

This feature is based on [Kubernetes Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) functionality.

#### Prerequisites

To enable the autoscaling feature, you need to use a cluster that has a [Metrics Server](https://github.com/kubernetes-sigs/metrics-server#readme) deployed and configured.

The Kubernetes Metrics Server collects resource metrics from the kubelets in your cluster, and exposes those metrics through the [Kubernetes API](https://kubernetes.io/docs/concepts/overview/kubernetes-api/), using an [APIService](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/) to add new kinds of resource that represent metric readings.

- Verify that Metrics Server is installed and returning metrics by completing the following steps:

  - Verify the installation by issuing the following command:

    ```bash
    kubectl get deploy,svc -n kube-system | egrep metrics-server
    ```

  - If Metrics Server is installed, the output is similar to the following example:

    ```bash
    deployment.extensions/metrics-server   1/1     1            1           3d4h
    service/metrics-server   ClusterIP   198.51.100.0   <none>        443/TCP         3d4h
    ```

  - Verify that Metrics Server is returning data for pods by issuing the following command:

    ```bash
    kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods"
    ```

To learn how to deploy the Metrics Server, see the [metrics-server installation guide](https://github.com/kubernetes-sigs/metrics-server#installation).

#### Enable Carto autoscaling feature

You can find an autoscaling config file example in [autoscaling config](customizations-examples/scale_components/autoscaling.yaml). Adding it with `-f customizations/scale_components/autoscaling.yaml` the `install` or `upgrade` is enough to start using the autoscaling feature.

You can edit the file to set your own scaling needs by modifying the minimum and maximum values.

### Enable static scaling

You can set statically set the number of pods should be running. To do it, use [static scale config](customizations-examples/scale_components/development.yaml) adding it with `-f customizations/scale_components/development.yaml` to the `install` or `upgrade` commands.

> Although we recommend the autoscaling configuration, you could choose the autoscaling feature for some components and the static configuration for the others. Remember that autoscaling override the static configuration, so if one component has both configurations, autoscaling will take precedence.

## High Availability

In some cases, you may want to ensure **some critical services have replicas deployed across different worker nodes** in order to provide high availability against a node failure. You can achieve this by applying one of the [high availability configurations](customizations-examples/high_availability) that we recommend.

> Note that you should enable static scaling or autoscaling for this setup to work as expected.

> In order to provide high availability across regions/zones, it's recommended to deploy each worker node in a different cloud provider regions/zones.

- [Standard HA](customizations-examples/high_availability/standard): configuration for an HA deployment
- [Standard HA with upgrades](customizations-examples/high_availability/standard_with_upgrades): configuration for an HA deployment, taking into account application upgrades.
- [High traffic HA](customizations-examples/high_availability/high_traffic): configuration for an HA deployment in high traffic environments.

## Capacity planning

Aligned with the [high availability configurations](customizations-examples/high_availability), please check the required cluster resources for each of the configurations:

- [Standard HA](customizations-examples/high_availability/standard/README.md#capacity-planning)
- [Standard HA with upgrades](customizations-examples/high_availability/standard_with_upgrades/README.md#capacity-planning)
- [High traffic HA](customizations-examples/high_availability/high_traffic/README.md#capacity-planning)

## Pod Disruption Budget

Along with the HA configurations, we can use `podDisruptionBudget` Kubernetes feature to define the budget of voluntary disruption by making the cluster aware of a minimum threshold in terms of available pods that the cluster needs to guarantee in order to ensure a baseline availability or performance.

This should be applied carefully using [this customization file](customizations-examples/pod_disruption_budget/customizations.yaml) to enable it for any of the deployments in the file.

You can either define a `maxUnavailable` or `minAvailable` parameters by entering integers or percentages. We recommend to [read the docs](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) before applying it.