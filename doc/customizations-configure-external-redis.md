### Configure external Redis

CARTO Self Hosted require a Redis (version 5+) to work. This Redis instance does not need persistance as it is used as a cache.

This package comes with an internal Redis but it is not recommended for production. It lacks any logic for backups or monitoring.

Here are some Terraform examples of databases created in different providers:

- [GCP Redis](https://github.com/CartoDB/carto-selfhosted/tree/master/examples/terraform/gcp/redis.tf).
- [AWS Redis](https://github.com/CartoDB/carto-selfhosted/tree/master/examples/terraform/aws/redis.tf).
- [Azure Redis](https://github.com/CartoDB/carto-selfhosted/tree/master/examples/terraform/azure/redis.tf).

In the same way as with Postgres, there are two alternatives regarding the secrets,
[set the secrets manually](#setup-redis-creating-secrets) and point to them from the configuration,
or let the chart to create the [secrets automatically](#setup-redis-with-automatic-secret-creation).

#### Setup Redis creating secrets

1. Add the secret:

```bash
kubectl create secret generic \
  -n <namespace> \
  mycarto-custom-redis-secret \
  --from-literal=password=<AUTH string password>
```

2. Configure the package:

Add the following lines to your `customizations.yaml` to connect to the external Redis:

```yaml
internalRedis:
  # Disable the internal Redis
  enabled: false
externalRedis:
  host: <Redis IP/Hostname>
  port: "6379"
  existingSecret: "mycarto-custom-redis-secret"
  existingSecretPasswordKey: "password"
  tlsEnabled: true
  # Only applies if your Redis TLS certificate it's self-signed
  # tlsCA: |
  #   -----BEGIN CERTIFICATE-----
  #   ...
  #   -----END CERTIFICATE-----
```

#### Setup Redis with automatic secret creation

1. Configure the package:
   Add the following lines to your `customizations.yaml` to connect to the external Redis:

```yaml
internalRedis:
  # Disable the internal Redis
  enabled: false
externalRedis:
  host: <Redis IP/Hostname>
  port: "6379"
  password: ""
  tlsEnabled: true
  # Only applies if your Redis TLS certificate it's self-signed
  # tlsCA: |
  #   -----BEGIN CERTIFICATE-----
  #   ...
  #   -----END CERTIFICATE-----
```

> Note: One kubernetes secret is going to be created automatically during the installation process with the `externalRedis.password` that you set in previous lines.

#### Configure Redis TLS

By default CARTO will try to connect to your Redis without TLS. In case you want to connect via TLS, you can configure it via the `externalRedis.tlsEnabled` parameter

```yaml
externalRedis:
  ...
  tlsEnabled: true
```

> :warning: In case you are connecting to a Redis where the TLS certificate is selfsigned or from a custom CA you can configure it via the `externalRedis.tlsCA` parameter

```yaml
externalRedis:
  ...
  tlsEnabled: true
  tlsCA: |
    #   -----BEGIN CERTIFICATE-----
    #   ...
    #   -----END CERTIFICATE-----
```