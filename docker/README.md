# Docker compose for for Carto 3

This directory contains a functional [`docker-compose.yaml`](https://github.com/CartoDB/carto3-helm/blob/initial-skeleton-dock-compose/docker/docker-compose.yaml) file. Run the application using it as shown below:

```console
curl -sSL https://raw.githubusercontent.com/CartoDB/carto3-helm/initial-skeleton-dock-compose/docker/docker-compose.yaml > docker-compose.yaml
docker-compose up -d
```

Once it is running check [the circle](http://localhost/circle.png) and [the hello world](http://localhost/workspace-api/) out, a static file will be served by Nginx and also basic Node.js application will print out a 'Hello World' message.