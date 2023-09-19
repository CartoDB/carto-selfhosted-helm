## How to apply the configurations

Create a dedicated [yaml](https://yaml.org/) file `customizations.yaml` for your configuration. For example, you could create a file with the next content:

```yaml
appConfigValues:
  selfHostedDomain: "my.domain.com"
# appSecrets:
#   googleMapsApiKey:
#     value: "<google-maps-api-key>"
#   # Other secrets, like buckets' configuration
```

> Follow [these steps](#tips-for-creating-the-customization-yaml-file) to create a well structured yaml file

And add the following at the end of ALL the `helm install` or `helm upgrade` command:

```bash
helm install .. -f customizations.yaml
```

You can also override values through the command-line to `helm`. Adding the argument: `--set key=value[,key=value]`