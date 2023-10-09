### External proxy

#### Important notes

:warning: Please consider the following important notes regarding the proxy configuration:

- CARTO self-hosted does not install any proxy component, instead it supports connecting to an existing proxy software deployed by the customer.

- CARTO Self-hosted supports both **HTTP** and **HTTPS** proxies.

- At the moment, password authentication is not supported for the proxy connection.

- [Importing data](https://docs.carto.com/carto-user-manual/data-explorer/importing-data) using an **HTTPS Proxy configured with a certificate signed by a Custom CA** currently has some limitations. Please, contact CARTO Support for this use case.
   - :information_source: Please check [Proxy HTTPS](#proxy-https) to understand the difference between a **custom CA** and a **well known CA**.

#### Configuration

CARTO self-hosted provides support for operating behind an HTTP or HTTPS proxy. The proxy acts as a gateway, enabling CARTO self-hosted components to establish connections with essential external services like Google APIs, Mapbox, and others.

A comprehensive list of domains that must be whitelisted by the proxy for the proper functioning of CARTO self-hosted can be found [here](customizations-examples/proxy/config/whitelisted_domains.md). The list includes domains for the essential core services of CARTO self-hosted, as well as additional optional domains that should be enabled to access specific features.

Add the following lines to your `customizations.yaml`, depending on the protocol your proxy uses.

##### Proxy HTTP

[customizations](../customizations/proxy/http/customizations.yaml) file.

- `externalProxy.excludedDomains`: Comma-separated list of domains to exclude from proxying.
   - :information_source: `.svc.cluster.local` must be in the list, to allow internal communication between components.

```yaml
externalProxy:
  enabled: true
  host: <Proxy IP/Hostname>
  port: <Proxy port>
  type: http
  excludedDomains: ["localhost,.svc.cluster.local"]
```

##### Proxy HTTPS

> :warning: Currently, using a Snowflake connection with a Proxy HTTPS is not supported.

[customizations](../customizations/proxy/https/customizations.yaml) file.

- `externalProxy.excludedDomains` (optional): Comma-separated list of domains to exclude from proxying.
   - :information_source: `.svc.cluster.local` must be in the list, to allow internal communication between components.
- `externalProxy.sslCA` (optional): Path to the proxy CA certificate.
   - :information_source: Please read carefully the [important notes](#important-notes) to understand the current limitations with **custom CAs**.
   - :information_source: If the proxy certificate is signed by a **custom CA**, such CA must be included here.
   - :information_source: If the proxy certificate is signed by a **well known CA**, there is no need to add it here. **Well known CAs** are usually part of the [ca-certificates package](https://askubuntu.com/questions/857476/what-is-the-use-purpose-of-the-ca-certificates-package)
- `externalProxy.sslRejectUnauthorized` (optional): Specify if CARTO Self-hosted should check if the proxy certificate is valid (`1`) or not (`0`).
   - :information_source: For instance, **self signed certificates** validation must be skipped.

```yaml
externalProxy:
  enabled: true
  host: <Proxy IP/Hostname>
  port: <Proxy port>
  type: https
  excludedDomains: ["localhost,.svc.cluster.local"]
  ## NOTE: Please, carefully read CARTO Self-hosted proxy documentation to understand the  the current limitations with [custom CAs].
  sslRejectUnauthorized: true
  # sslCA: |
  #  -----BEGIN CERTIFICATE-----
  #  XXXXXXXXXXXXXXXXXXXXXXXXXXX
  #  -----END CERTIFICATE-----
```

#### Supported datawarehouses

Note that while certain data warehouses can be configured to work with the proxy, **there are others that will inherently bypass it**. Therefore, if you have a restrictive network policy in place, you will need to explicitly allow this egress non-proxied traffic.

 | Datawarehouse | Proxy HTTP | Proxy HTTPS | Automatic proxy bypass ** |
 | ------------- | ---------- | ----------- | ------------------------- |
 | BigQuery      | Yes        | Yes         | N/A                       |
 | Snowflake     | Yes        | No          | No ***                    |
 | Databricks    | No         | No          | Yes                       |
 | Postgres      | No         | No          | Yes                       |
 | Redshift      | No         | No          | Yes                       |

> :warning: \*\* There's no need to include the non supported datawarehouses in the `externalProxy.excludedDomains` list. CARTO self-hosted components will automatically attempt a direct connection to those datawarehouses, with the exception of **HTTPS Proxy + Snowflake**.

> :warning: \*\*\* If an HTTPS proxy is required in your deployment and you are a Snowflake Warehouse user, you need to explicitly exclude snowflake traffic using the configuration below:

```
externalProxy:
  enabled: true
  host: <Proxy IP/Hostname>
  port: <Proxy port>
  type: https
  ## Check your Snowflake warehouse URL
  excludedDomains: ["localhost,.svc.cluster.local,.snowflakecomputing.com"]
```

#### Enhaced control over non-proxied egress traffic

When no network policy is enforced, all outgoing traffic that does not pass through a proxy will be permitted.

In restrictive environments, it is important to maintain strict control over connections made by CARTO self-hosted components. To achieve this, you should configure your proxy to allow only approved external services (whitelisting), while blocking any other outgoing traffic that does not go through the proxy.

To accomplish this, you can apply a network policy, such as the one provided in this [example](../customizations/proxy/network_policy/restricted-internet-access-network-policy.yaml).