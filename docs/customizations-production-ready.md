## Production Ready

The default Helm configuration provided by CARTO works out of the box, but it's **not production ready**.
There are several things to prepare to make it production ready:

1. [Configure the domain](#configure-the-domain-of-your-self-hosted) that will be used.
2. [Expose service](#access-to-carto-from-outside-the-cluster) to be accessed from outside the cluster.
   - [Configure TLS termination](#configure-tls-termination-in-the-service)
3. [Use external Databases](#configure-external-postgres). Our recommendation is to use managed DBs with backups and so on.

Optional configurations:

- [Configure scale of the components](#components-scaling)
- [Use your own bucket to store the data](#custom-buckets) (by default, GCP CARTO buckets are used)