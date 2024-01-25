## High Availability configuration: Standard with upgrades

### Requirements

- NodePool with at least 2 nodes
- NodePool with at least `39gb RAM` and `22 CPUs` for workloads, in order to avoid evictions if the minimal number of replicas approaches to the limits

### Setup

- A replica of each component will be placed in a different node, ensuring application high availability if a node goes down.

### Application upgrades

- A third replica will be triggered for the upgrade operation, ensuring that the other two replicas remain up and running.

### Capacity planning

component            |  scale  |  limits.memory  |  limits.cpu  |  requests.memory  |  requests.cpu  |  HA.minReplicas  |  HA.maxreplicas  |  HA.targetCPU
---------------------|---------|-----------------|--------------|-------------------|----------------|------------------|------------------|--------------
accountsWww          |  true   |  1024Mi         |  500m        |  768Mi            |  200m          |  2               |  3               |  75
importApi            |  true   |  1024Mi         |  1000m       |  372Mi            |  350m          |  2               |  3               |  75
importWorker         |  false  |  8192Mi         |  2000m       |  3072Mi           |  350m          |                  |                  |
ldsApi               |  true   |  1024Mi         |  1000m       |  768Mi            |  350m          |  2               |  3               |  75
mapsApi              |  true   |  6144Mi         |  2000m       |  768Mi            |  350m          |  2               |  3               |  75
sqlWorker            |  false  |  2048Mi         |  1000m       |  1024Mi           |  350m          |                  |                  |
router               |  true   |  512Mi          |  500m        |  372Mi            |  200m          |  2               |  3               |  75
httpCache            |  false  |  2048Mi         |  500m        |  1256Mi           |  200m          |                  |                  |
notifier             |  false  |  512Mi          |  500m        |  256Mi            |  200m          |                  |                  |
cdnInvalidatorSub    |  false  |  1024Mi         |  500m        |  372Mi            |  200m          |                  |                  |
workspaceApi         |  true   |  1360Mi         |  1000m       |  768Mi            |  350m          |  2               |  3               |  75
workspaceSubscriber  |  false  |  1024Mi         |  500m        |  372Mi            |  200m          |                  |                  |
workspaceWww         |  true   |  1024Mi         |  500m        |  768Mi            |  200m          |  2               |  3               |  75
**TOTAL with max replicas** |  |  39072Mi        |  22500m      |  15520Mi          |  6800m         |                  |                  |
