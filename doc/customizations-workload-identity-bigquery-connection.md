## Workload Identity BigQuery connection

CARTO self-hosted running on a GKE cluster (Google Cloud Platform) can take advantage of [GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) feature to create a connection between the self-hosted and BigQuery without any user action.

> :warning: This feature is available from Carto self-hosted Helm version `1.43.12 / 2023.2.2` onwards, **running on a GKE cluster**.

### Configuration

1. Setup [GKE Workload Identity for Carto self-hosted](https://github.com/CartoDB/carto-selfhosted-helm/blob/main/doc/gke/gke-workload-identity.md) following the documentation.

2. Copy the [customizations.yaml](../customizations/workload_identity_connection/customizations.yaml) from the examples.

3. Set the `customizations.yaml` environment variables with the appropiate values:
4. - `WORKSPACE_WORKLOAD_IDENTITY_WORKFLOWS_TEMP`: BigQuery dataset id used for storing temporary tables (i.e. `my_gcp_project.my_dataset`). Needed for compatibility with upcoming features.
   - `WORKSPACE_WORKLOAD_IDENTITY_BILLING_PROJECT`: GCP project to be charged with the BigQuery costs.
   - `WORKSPACE_WORKLOAD_IDENTITY_SERVICE_ACCOUNT_EMAIL`: Service account email configured for Workload Identity.
   - `WORKSPACE_WORKLOAD_IDENTITY_CONNECTION_OWNER_ID`: Id of the Carto user who will be the owner of the connection (i.e. `"auth0|3idsj230990sj4wsddd10"`). This can be obtained by running the following `curl` command:
     ```bash
     curl -s 'https://accounts.app.carto.com/users/me' \
       -H 'Authorization: Bearer <your_carto_jwt_token>' \
       | jq '.user_id'
     ```

5. Grant your Workload Identity service account with BigQuery RW access to your Datawarehouse dataset or project.

6. Run a Helm install/upgrade including the `customizations.yaml` file mentioned above:
   ```bash
   helm upgrade <installation_name> \
     carto/carto \
     --install \
     --dependency-update \
     --namespace <namespace> \
     -f carto-values.yaml \
     -f carto-secrets.yaml \
     -f customizations.yaml
   ```

7. Follow the previous command output and grant the service account the following role:
   ```bash
   gcloud iam service-accounts add-iam-policy-binding \
   <workload_identity_service_account_email> \
   --role roles/iam.workloadIdentityUser \
   --member "serviceAccount:<gke_cluster_project_id>.svc.id.goog[<namespace>/carto-common-backend]" \
   --project <gke_cluster_project_id>
   ```