## High Availability configuration: Standard with upgrades

### Requirements

- NodePool with at least 2 nodes

### Setup

- A replica of each component will be placed in a different node, ensuring application high availability if a node goes down.

### Application upgrades

- A third replica will be triggered for the upgrade operation, ensuring that the other two replicas remain up and running.
