## Tips for creating the customization Yaml file

Here you can find some basic instructions in order to create the config yaml file for your environment:

- The configuration file `customizations.yaml` will be composed of keys and their value, please do not define the same key several times, because they will be overridden between them. Each key in the yaml file would have subkeys for different configurations, so all of them should be inside the root key. Example:

  ```yaml
  mapsApi:
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 3
      targetCPUUtilizationPercentage: 75
  ```

- Check the text values of the `customizations.yaml` keys, they have to be set between quotes. Example:

  ```yaml
  appConfigValues:
    selfHostedDomain: "my.domain.com"
  ```

  Note that integers and booleans values are set without quotes.

- Once we have the config files ready, we would be able to check the values that are going to be used by the package with this command:

  ```bash
  helm template \
  mycarto \
  carto/carto \
  --namespace <your_namespace> \
  -f carto-values.yaml \
  -f carto-secrets.yaml \
  -f customizations.yaml
  ```