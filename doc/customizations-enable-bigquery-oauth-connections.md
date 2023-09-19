### Enable BigQuery OAuth connections

This feature allows users to create a BigQuery connection using `Sign in with Google` instead of providing a service account key.

> :warning: Connections created with OAuth cannot be shared with other organization users.

1. Create an OAuth consent screen inside the desired GCP project:

   - Introduce an app name and a user support email.
   - Add an authorized domain (the one used in your email).
   - Add another email as dev contact info (it can be the same).
   - Add the following scopes: `./auth/userinfo.email`, `./auth/userinfo.profile` & `./auth/bigquery`.

2. Create the OAuth credentials:

   - Type: Web application.
   - Authorized JavaScript origins: `https://<your_selfhosted_domain>`.
   - Authorized redirect URIs: `https://<your_selfhosted_domain>/connections/bigquery/oauth`.
   - Download the credentials file.

3. Follow [these guidelines](https://github.com/CartoDB/carto-selfhosted-helm/blob/main/customizations/README.md#how-to-apply-the-configurations) to add the following lines to your `customizations.yaml` populating them with the credential's file corresponding values:

```yaml
appConfigValues:
  bigqueryOauth2ClientId: "<value_from_credentials_web_client_id>"

appSecrets:
  bigqueryOauth2ClientSecret:
    value: "<value_from_credentials_web_client_secret>"
```