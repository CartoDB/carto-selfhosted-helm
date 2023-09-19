### Configure the domain of your Self Hosted

The most important step to have your CARTO Self Hosted ready to be used is to configure the domain to be used.

> ⚠️ CARTO Self Hosted is not designed to be used in the path of a URL, it needs a full domain or subdomain. ⚠️

To do this you need to [add the following customization](#how-to-apply-the-configurations):

```yaml
appConfigValues:
  selfHostedDomain: "my.domain.com"
```