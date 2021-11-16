# Docker image for Carto 3

## Using Docker Compose

The main folder of this repository contains a functional [`docker-compose.yaml`](https://github.com/CartoDB/carto3-helm/blob/initial-skeleton-dock-compose/docker/docker-compose.yaml) file. Run the application using it as shown below:

```console
$ curl -sSL https://raw.githubusercontent.com/CartoDB/carto3-helm/initial-skeleton-dock-compose/docker/docker-compose.yaml > docker-compose.yaml
$ docker-compose up -d
```