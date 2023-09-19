### Configure TLS termination in the CARTO router service

> :point_right: Do not use this configuration if you are exposing CARTO services with an Ingress

#### Disable internal HTTPS

> ⚠️ CARTO Self Hosted only works if the final client use HTTPS protocol. ⚠️

If you need to disable `HTTPS` in the Carto router, [add the following lines](#how-to-apply-the-configurations) to your `customizations.yaml`:

```yaml
tlsCerts:
  httpsEnabled: false
```

> ⚠️ Remember that CARTO only works with `HTTPS`, so if you disable this protocol in the Carto Router component you should configure it in a higher layer like a Load Balancer (service or ingress) to make the redirection from `HTTP` to `HTTPS` ⚠️

#### Use your own TLS certificate

By default, the package generates a self-signed certificate with a validity of 365 days.

If you want to add your own certificate you need:

- Create a kubernetes secret with following content:

  ```bash
  kubectl create secret tls -n <namespace> <certificate name> \
    --cert=path/to/cert/file \
    --key=path/to/key/file
  ```

- Add the following lines to your `customizations.yaml`:

  ```yaml
  tlsCerts:
    httpsEnabled: true
    autoGenerate: false
    existingSecret:
      name: "mycarto-custom-tls-certificate"
      keyKey: "tls.key"
      certKey: "tls.crt"
  ```