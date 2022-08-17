## High Availability configuration: Standard

### Requirements

- NodePool with at least 2 nodes

### Setup

- A replica of each component will be placed in a differente node ensuring application high availability if a node goes down.

### Application upgrades

- One of the replicas will be replaced by the new one during the upgrade process.
