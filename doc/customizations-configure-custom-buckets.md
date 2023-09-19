### Custom Buckets

For every CARTO Self Hosted installation, we create GCS buckets on our side as part of the required infrastructure for importing data, map thumbnails and customization assets (custom logos and markers).

You can create and use your own storage buckets in any of the following supported storage providers:

- Google Cloud Storage. [Terraform code example](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/gcp/storage.tf).
- AWS S3. [Terraform code example](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/aws/storage.tf).
- Azure Storage. [Terraform code example](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/azure/storage.tf).

> :warning: You can only set one provider at a time.

#### Pre-requisites

1. Create 3 buckets in your preferred Cloud provider:

   - Client Bucket
   - Thumbnails Bucket

   > :warning: Map thumbnails storage objects (.png files) can be configured to be `public` (default) or `private`. In order to change this, set `appConfigValues.workspaceThumbnailsPublic: "false"`. For the default configuration to work, the bucket must allow public objects/blobs. Some features, such as branding and custom markers, won't work unless the bucket is public. However, there's a workaround to avoid making the whole bucket public, which requires allowing public objects, allowing ACLs (or non-uniform permissions) and disabling server-side encryption.

   > There're no name constraints.

2. CORS configuration: The Thumbnails and Client buckets require having the following CORS headers configured.
   - Allowed origins: `*`
   - Allowed methods: `GET`, `PUT`, `POST`
   - Allowed headers (common): `Content-Type`, `Content-MD5`, `Content-Disposition`, `Cache-Control`
     - GCS (extra): `x-goog-content-length-range`, `x-goog-meta-filename`
     - Azure (extra): `Access-Control-Request-Headers`, `X-MS-Blob-Type`
   - Max age: `3600`

   > CORS is configured at bucket level in GCS and S3, and at storage account level in Azure.

   > How do I setup CORS configuration? Check the provider docs: [GCS](https://cloud.google.com/storage/docs/configuring-cors), [AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/enabling-cors-examples.html), [Azure Storage](https://docs.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services#enabling-cors-for-azure-storage).

3. Generate credentials with Read/Write permissions to access those buckets, our supported authentication methods are:

   - GCS: Service Account Key
   - AWS: Access Key ID and Secret Access Key
   - Azure: Access Key

#### Google Cloud Storage

In order to use Google Cloud Storage custom buckets you need to:

1. Create the buckets.

   > :warning: If you enable `Prevent public access` in the bucket properties, then set `appConfigValues.workspaceThumbnailsPublic` and `appConfigValues.workspaceImportsPublic` to `false`.

2. Configure the required [CORS settings](#pre-requisites).

3. Add the following lines to your `customizations.yaml` and replace the `<values>` with your own settings:

   ```yaml
   appConfigValues:
     storageProvider: "gcp"
     workspaceImportsBucket: <client_bucket_name>
     workspaceImportsPublic: <false|true>
     workspaceThumbnailsBucket: <thumbnails_bucket_name>
     workspaceThumbnailsPublic: <false|true>
     thumbnailsBucketExternalURL: <public or authenticated external bucket URL>
     googleCloudStorageProjectId: <gcp_project_id>
   ```

   > Note that thumbnailsBucketExternalURL could be https://storage.googleapis.com/<thumbnails_bucket_name>/ for public access or https://storage.cloud.google.com/<thumbnails_bucket_name>/ for authenticated access.

4. Select a **Service Account** that will be used by the application to interact with the buckets. There are three options:

   - using a [custom Service Account](#custom-service-account), that will be used not only for the buckets, but for the services deployed by CARTO as well. If you are using Workload Identity, that's your option.
   - using a dedicated Service Account **only for the buckets**

5. Grant the selected Service Account with the role `roles/iam.serviceAccountTokenCreator` in the GCP project where it was created.

   > :warning: We don't recommend granting this role at project IAM level, but instead at the Service Account permissions level (IAM > Service Accounts > `your_service_account` > Permissions).

6. Grant the selected Service Account with the role `roles/storage.admin` to the buckets created.

7. [OPTIONAL] Pass your GCP credentials as secrets: **This is only required if you are going to use a dedicated Service Account only for the buckets** (option 4.2).

   - **Option 1: Automatically create the secret:**

     ```yaml
     appSecrets:
       googleCloudStorageServiceAccountKey:
         value: |
           <REDACTED>
     ```

     > `appSecrets.googleCloudStorageServiceAccountKey.value` should be in plain text, preserving the multiline and correctly tabulated.

   - **Option 2: Using existing secret:**
     Create a secret running the command below, after replacing the `<PATH_TO_YOUR_SECRET.json>` value with the path to the file of the Service Account:

     ```bash
     kubectl create secret generic \
       [-n my-namespace] \
       mycarto-google-storage-service-account \
       --from-file=key=<PATH_TO_YOUR_SECRET.json>
     ```

     Add the following lines to your `customizations.yaml`, without replacing any value:

     ```yaml
     appSecrets:
       googleCloudStorageServiceAccountKey:
         existingSecret:
           name: mycarto-google-storage-service-account
           key: key
     ```

#### AWS S3

In order to use AWS S3 custom buckets you need to:

1. Create the buckets.

   > :warning: If you enable `Block public access` in the bucket properties, then set `appConfigValues.workspaceThumbnailsPublic` and `appConfigValues.workspaceImportsPublic` to `false`.

2. Configure the required [CORS settings](#pre-requisites).

3. Create an IAM user and generate a programmatic key ID and secret.

4. Grant this user with read/write access permissions over the buckets. If server-side encryption is enabled, the user must be granted with permissions over the KMS key used.

5. Add the following lines to your `customizations.yaml` and replace the `<values>` with your own settings:

```yaml
appConfigValues:
  storageProvider: "s3"
  workspaceImportsBucket: <client_bucket_name>
  workspaceImportsPublic: <false|true>
  workspaceThumbnailsBucket: <thumbnails_bucket_name>
  workspaceThumbnailsPublic: <false|true>
  thumbnailsBucketExternalURL: <external bucket URL>
  awsS3Region: <s3_buckets_region>
```

> Note that thumbnailsBucketExternalURL should be https://<thumbnails_bucket_name>.s3.amazonaws.com/

6. Pass your AWS credentials as secrets by using one of the options below:

   - **Option 1: Automatically create a secret:**

   Add the following lines to your `customizations.yaml` replacing it with your access key values:

   ```yaml
   appSecrets:
     awsAccessKeyId:
       value: "<REDACTED>"
     awsAccessKeySecret:
       value: "<REDACTED>"
   ```

   > `appSecrets.awsAccessKeyId.value` and `appSecrets.awsAccessKeySecret.value` should be in plain text

   - **Option 2: Using an existing secret:**
     Create a secret running the command below, after replacing the `<REDACTED>` values with your key values:

   ```bash
   kubectl create secret generic \
     [-n my-namespace] \
     mycarto-custom-s3-secret \
     --from-literal=awsAccessKeyId=<REDACTED> \
     --from-literal=awsSecretAccessKey=<REDACTED>
   ```

   > Use the same namespace where you are installing the helm chart

   Add the following lines to your `customizations.yaml`, without replacing any value:

   ```yaml
   appSecrets:
     awsAccessKeyId:
       existingSecret:
         name: mycarto-custom-s3-secret
         key: awsAccessKeyId
     awsAccessKeySecret:
       existingSecret:
         name: mycarto-custom-s3-secret
         key: awsSecretAccessKey
   ```

#### Azure Storage

In order to use Azure Storage buckets (aka containers) you need to:

1. Create an storage account if you don't have one already.

2. Configure the required [CORS settings](#pre-requisites).

3. Create the storage buckets. If you set the `Public Access Mode` to `private` in the bucket properties, make sure you set `appConfigValues.workspaceThumbnailsPublic` to `false`.

   > :warning: If you set the `Public Access Mode` to `private` in the bucket properties, then set `appConfigValues.workspaceThumbnailsPublic` and `appConfigValues.workspaceImportsPublic` to `false`.

4. Generate an Access Key, from the storage account's Security properties.

5. Add the following lines to your `customizations.yaml` and replace the `<values>` with your own settings:

```yaml
appConfigValues:
  storageProvider: "azure-blob"
  azureStorageAccount: <storage_account_name>
  workspaceImportsBucket: <client_bucket_name>
  workspaceImportsPublic: <false|true>
  workspaceThumbnailsBucket: <thumbnails_bucket_name>
  thumbnailsBucketExternalURL: <external bucket URL>
  workspaceThumbnailsPublic: <false|true>
```

> Note that thumbnailsBucketExternalURL should be https://<azure_resource_group>.blob.core.windows.net/<thumbnails_bucket_name>/

6. Pass your credentials as secrets by using one of the options below:

   - **Option 1: Automatically create the secret:**

   ```yaml
   appSecrets:
     azureStorageAccessKey:
       value: "<REDACTED>"
   ```

   > `appSecrets.azureStorageAccessKey.value` should be in plain text

   - **Option 2: Using existing secret:**
     Create a secret running the command below, after replacing the `<REDACTED>` values with your key values:

   ```bash
   kubectl create secret generic \
     [-n my-namespace] \
     mycarto-custom-azure-secret \
     --from-literal=azureStorageAccessKey=<REDACTED>
   ```

   > Use the same namespace where you are installing the helm chart

   Add the following lines to your `customizations.yaml`, without replacing any value:

   ```yaml
   appSecrets:
     awsAccessKeyId:
       existingSecret:
         name: mycarto-custom-azure-secret
         key: azureStorageAccessKey
   ```