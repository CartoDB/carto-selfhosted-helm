## High Availability configuration: High traffic

### Requirements

- NodePool with at least 2 nodes

### Setup

- A replica of each component will be placed in a different node ensuring application high availability if a node goes down.

### Application upgrades

- A third replica will be triggered for the upgrade operation, ensuring that the other two replicas remain up and running.
- For components with more than 3 replicas, one of the replicas will be replaced during the upgrade.

### High traffic

- The CARTO components getting most of the requests will scale up to `maxReplicas` in order to cope with the traffic load, under high traffic conditions.
