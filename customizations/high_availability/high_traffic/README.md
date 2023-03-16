## High Availability configuration: High traffic

### Requirements

- NodePool with at least 2 nodes
- NodePool with at least `26gb RAM` and `15 CPUs` for workloads, in order to avoid evictions if the minimal number of replicas approaches to the limits

### Setup

- A replica of each component will be placed in a different node, ensuring application high availability if a node goes down.

### Application upgrades

- A third replica will be triggered for the upgrade operation, ensuring that the other two replicas remain up and running.
- For components with more than 3 replicas, one of the replicas will be replaced during the upgrade.

### High traffic

- The CARTO components getting most of the requests will scale up to `maxReplicas` in order to cope with the traffic load, under high traffic conditions.

### Capacity planning


component            |  scale    |  limits.memory  |  limits.cpu  |  requests.memory  |  requests.cpu  |  HA.minReplicas  |  HA.maxreplicas  |  HA.targetCPU
---------------------|-----------|-----------------|--------------|-------------------|----------------|------------------|------------------|--------------
accountsWww          |  true     |  1024Mi         |  500m        |  768Mi            |  200m          |  2               |  3               |  75
importApi            |  true     |  512Mi          |  1000m       |  372Mi            |  350m          |  2               |  3               |  75
importWorker         |  false    |  4096Mi         |  1000m       |  3072Mi           |  350m          |                  |                  |
ldsApi               |  true     |  1024Mi         |  1000m       |  768Mi            |  350m          |  2               |  3               |  75
mapsApi              |  true     |  2048Mi         |  1000m       |  768Mi            |  350m          |  2               |  6               |  75
sqlWorker            |  false    |  4096Mi         |  1000m       |  3072Mi           |  350m          |                  |                  |
router               |  true     |  1536Mi          |  1000m        |  1396Mi            |  450m          |  2               |  3               |  75
httpCache            |  false    |  2048Mi         |  500m        |  1256Mi           |  200m          |                  |                  |
notifier             |  false    |  512Mi          |  500m        |  256Mi            |  200m          |                  |                  |
cdnInvalidatorSub    |  false    |  512Mi          |  500m        |  372Mi            |  200m          |                  |                  |
workspaceApi         |  true     |  1024Mi         |  1000m       |  768Mi            |  350m          |  2               |  6               |  75
workspaceSubscriber  |  false    |  512Mi          |  500m        |  372Mi            |  200m          |                  |                  |
workspaceWww         |  true     |  1024Mi         |  500m        |  768Mi            |  200m          |  2               |  3               |  75
**TOTAL**            |           |  45568Mi        |  28000m      |  29832Mi          |  10350m         |                  |                  |
