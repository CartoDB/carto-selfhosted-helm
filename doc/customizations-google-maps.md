### Google Maps

In order to enable Google Maps basemaps inside CARTO Self Hosted, you need to own a Google Maps API key and add one of the options below to your `customizations.yaml` following [these guidelines](https://github.com/CartoDB/carto-selfhosted-helm/blob/main/customizations/README.md#how-to-apply-the-configurations):

- **Option 1: Automatically create the secret:**

```yaml
appSecrets:
  googleMapsApiKey:
    value: "<REDACTED>"
```

> `appSecrets.googleMapsApiKey.value` should be in plain text

- **Option 2: Using existing secret:**
  Create a secret running the command below, after replacing the `<REDACTED>` values with your key values:

```bash
  kubectl create secret generic \
  [-n my-namespace] \
  mycarto-google-maps-api-key \
  --from-literal=googleMapsApiKey=<REDACTED>
```

Add the following lines to your `customizations.yaml`, without replacing any value:

```yaml
appSecrets:
  googleMapsApiKey:
    existingSecret:
      name: mycarto-google-maps-api-key
      key: googleMapsApiKey
```