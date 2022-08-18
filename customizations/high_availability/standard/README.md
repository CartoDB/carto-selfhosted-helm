## High Availability configuration: Standard

### Requirements

- NodePool with at least 2 nodes
- NodePool with at least `26gb RAM` and `15 CPUs` for workloads, in order to avoid evictions if the minimal number of replicas approaches to the limits

### Setup

- A replica of each component will be placed in a different node, ensuring application high availability if a node goes down.

### Application upgrades

- One of the replicas will be replaced by the new one during the upgrade process.

### Capacity planning

component            |  scale  |  limits.memory  |  limits.cpu  |  requests.memory  |  requests.cpu  |  HA.minReplicas  |  HA.maxreplicas  |  HA.targetCPU
---------------------|---------|-----------------|--------------|-------------------|----------------|------------------|------------------|--------------
accountsWww          |  true   |  1024Mi         |  500m        |  768Mi            |  200m          |  2               |  2               |  75
importApi            |  true   |  512Mi          |  1000m       |  372Mi            |  350m          |  2               |  2               |  75
importWorker         |  false  |  4096Mi         |  1000m       |  3072Mi           |  350m          |                  |                  |
ldsApi               |  true   |  1024Mi         |  1000m       |  768Mi            |  350m          |  2               |  2               |  75
mapsApi              |  true   |  2048Mi         |  1000m       |  768Mi            |  350m          |  2               |  2               |  75
sqlWorker            |  false  |  4096Mi         |  1000m       |  3072Mi           |  350m          |                  |                  |
router               |  true   |  512Mi          |  500m        |  372Mi            |  200m          |  2               |  2               |  75
httpCache            |  false  |  2048Mi         |  500m        |  1256Mi           |  200m          |                  |                  |
cdnInvalidatorSub    |  false  |  512Mi          |  500m        |  372Mi            |  200m          |                  |                  |
workspaceApi         |  true   |  1024Mi         |  1000m       |  768Mi            |  350m          |  2               |  2               |  75
workspaceSubscriber  |  false  |  512Mi          |  500m        |  372Mi            |  200m          |                  |                  |
workspaceWww         |  true   |  1024Mi         |  500m        |  768Mi            |  200m          |  2               |  2               |  75
**TOTAL**                |         |  25600Mi        |  14500m      |  17312Mi          |  5300m         |                  |                  |

