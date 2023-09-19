## Troubleshooting

### Diagnosis tool

If you need to open a support ticket, please execute our [carto-support-tool](../tools/) to obtain all the necessary information and attach it to the ticket.

### Ingress

- The ingress creation can take several minutes, once finished you should see this status:

  ```bash
  kubectl get ingress -n <namespace>
  kubectl describe ingress <name>
  ```

  ```bash
  Events:
    Type     Reason     Age                  From                     Message
    ----     ------     ----                 ----                     -------
    Normal   Sync       9m35s                loadbalancer-controller  UrlMap "k8s2-um-carto-router-zzud3" created
    Normal   Sync       9m29s                loadbalancer-controller  TargetProxy "k8s2-tp-carto-router-zzud3" created
    Normal   Sync       9m19s                loadbalancer-controller  ForwardingRule "k8s2-fr-carto-router-zzud3" created
    Normal   Sync       9m11s                loadbalancer-controller  TargetProxy "k8s2-ts--carto-router-zzud3" created
    Normal   Sync       9m1s                 loadbalancer-controller  ForwardingRule "k8s2-fs-carto-router-zzud3" created
    Normal   IPChanged  9m1s                 loadbalancer-controller  IP is now 34.149.xxx.xx
  ```

- A common error could be that the certificate creation for the Load Balancer in GCP will be in a failed status, you could execute these commands to debug it:

  ```bash
    kubectl get ingress carto-router -n <namespace>
    kubectl describe ingress carto-router -n <namespace>
    export SSL_CERT_ID=$(kubectl get ingress carto-router -n <namespace> -o jsonpath='{.metadata.annotations.ingress\.kubernetes\.io/ssl-cert}')
    gcloud --project <project> compute ssl-certificates list
    gcloud --project <project> compute ssl-certificates describe ${SSL_CERT_ID}
  ```

- `500 Code Error`

  You have configured your Ingress with your own certificate and you are seeing this error:

  ```bash
    Request URL: https://carto.example.com/workspace-api/accounts/ac_XXXXX/check
    Request Method: GET
    Status Code: 500

    Response: {"error":"unable to verify the first certificate","status":500,"code":"UNABLE_TO_VERIFY_LEAF_SIGNATURE"}
  ```

  This error means that your cert has not the certificate chain complete. Probably your cert has been signed by a intermediate CA, and this issuer needs to be added to your cert. In this case, you have to recreate your kubernetes tls secret certificate again with all the issuers and recreate the installation with `helm delete` and `helm install`. Please see the [uninstall steps](https://github.com/CartoDB/carto-selfhosted-helm#update)

  These steps could be useful for you:

  - Get the PEM or CRT file and split the certificate chain in multiple files

    ```bash
    cat carto.example.crt | \
      awk 'split_after == 1 {n++;split_after=0} \
      /-----END CERTIFICATE-----/ {split_after=1} \
      {print > "cert_chain" n ".crt"}'
    ```

    ```bash
    ls -ltr cert_chain*
    ```

  - Get who is the signer / issuer of each of the certificate chain certs

    ```bash
    for CERT in $(ls cert_chain*.crt); do echo -e "------------------------\n";openssl x509 -in ${CERT} -noout -text | egrep "Issuer:|Subject:"; echo -e "------------------------\n";  done
    ```

    ```yaml
    ------------------------

            Issuer: C = US, ST = New Jersey, L = Jersey City, O = The USERTRUST Network, CN = USERTrust RSA Certification Authority
            Subject: C = GB, ST = Greater Manchester, L = Salford, O = Sectigo Limited, CN = Sectigo RSA Domain Validation Secure Server CA
    ------------------------

    ------------------------

            Issuer: C = GB, ST = Greater Manchester, L = Salford, O = Sectigo Limited, CN = Sectigo RSA Domain Validation Secure Server CA
            Subject: CN = *.carto.example
    ------------------------
    ```

  - Identify the issuer that is missing in your Ingress certificate file.

  - Include the missing certificate in the chain and validate it with the certificate key. Usually it should go to the bottom of the file.

    **NOTE**: this certificates use to come with the bundle sent when the certificate was renewed. In this example the missing certificate is the `USERTrust`

    ```bash
    cat carto.example.crt USERTrustRSAAAACA.crt > carto.example.new.crt
    ```

  - Verify the md5

    ```bash
    openssl x509 -noout -modulus -in carto.example.new.crt | openssl md5
    openssl rsa -noout -modulus -in carto.example.key | openssl md5
    ```

    **NOTE**: If both `modulus md5` does not match (the output of both commands should be exactly the same), the certificate that you have updated won't be valid. From here, you need to iterate with the certificate update operation (previous step), until both `modulus md5` match.

  - Create your new certificate in a kubernetes tls secret

    ```bash
    kubectl create secret tls -n <namespace> carto-example-new --cert=carto.example.new.crt --key=carto.example.key
    ```

  - Reinstall your environment

    [uninstall steps](https://github.com/CartoDB/carto-selfhosted-helm#update)

    [install steps](https://github.com/CartoDB/carto-selfhosted-helm#installation-steps)

- Message ` type "ClusterIP", expected "NodePort" or "LoadBalancer"`

  This message is related to how is configured your cluster. To use ClusterIP the service needs to point to a NEG. This can be done using `cloud.google.com/neg: '{"ingress": true}'`annotation in router service. Container-native load balancing is enabled by default for Services when all of the following conditions are true:

  - For Services created in GKE clusters 1.17.6-gke.7 and up
  - Using VPC-native clusters
  - Not using a Shared VPC
  - Not using GKE Network Policy
    If this is not your case you must add it in your customization.yaml file. in the example in this repository this value is commented, if you are using it just uncomment it and reinstall.

  ```yaml
  service:
    annotations:
      ## Same BackendConfig for all Service ports
      ## https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#same_backendconfig_for_all_service_ports
      cloud.google.com/backend-config: '{"default": "carto-service-backend-config"}'
      ## https://cloud.google.com/kubernetes-engine/docs/how-to/container-native-load-balancing if your
      ## installation do not match with the configuration below:
      ## For Services created in GKE clusters 1.17.6-gke.7 and up
      ##  * Using VPC-native clusters
      ##  * Not using a Shared VPC
      ##  * Not using GKE Network Policy
      ## If it is not your case, uncomment the line below
      cloud.google.com/neg: '{"ingress": true}'
  ```
### Helm upgrade fails: another operation (install/upgrade/rollback) is in progress

If you face a problem like the one below while you are updating your CARTO selfhosted installation```
```bash
helm upgrade my-release carto/carto --namespace my namespace -f carto-values.yaml -f carto-secrets.yaml -f customizations.yml
Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
```

Probably an upgrade operation wasn't killed gracefully. The fix is to rollback to a previous deployment:

```bash
helm history my-release

REVISION	UPDATED                 	STATUS         	CHART             	APP VERSION	DESCRIPTION
19      	Fri Aug 26 11:10:20 2022	superseded     	carto-1.40.6-beta 	2022.8.19-2	Upgrade complete
20      	Fri Sep 16 12:00:57 2022	superseded     	carto-1.42.1-beta 	2022.9.16  	Upgrade complete
21      	Mon Sep 19 16:46:46 2022	superseded     	carto-1.42.3-beta 	2022.9.19  	Upgrade complete
22      	Wed Sep 21 11:05:32 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
23      	Wed Sep 21 11:16:34 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
24      	Wed Sep 21 16:26:33 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
25      	Wed Sep 28 15:28:53 2022	superseded     	carto-1.42.10-beta	2022.9.28  	Upgrade complete
26      	Fri Sep 30 14:14:29 2022	superseded     	carto-1.42.10-beta	2022.9.28  	Upgrade complete
27      	Fri Sep 30 14:37:41 2022	deployed       	carto-1.42.10-beta	2022.9.28  	Upgrade complete
28      	Fri Sep 30 15:07:06 2022	pending-upgrade	carto-1.42.10-beta	2022.9.28  	Preparing upgrade
helm rollback my-release 27
Rollback was a success! Happy Helming!

helm history my-release

REVISION	UPDATED                 	STATUS         	CHART             	APP VERSION	DESCRIPTION
20      	Fri Sep 16 12:00:57 2022	superseded     	carto-1.42.1-beta 	2022.9.16  	Upgrade complete
21      	Mon Sep 19 16:46:46 2022	superseded     	carto-1.42.3-beta 	2022.9.19  	Upgrade complete
22      	Wed Sep 21 11:05:32 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
23      	Wed Sep 21 11:16:34 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
24      	Wed Sep 21 16:26:33 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
25      	Wed Sep 28 15:28:53 2022	superseded     	carto-1.42.10-beta	2022.9.28  	Upgrade complete
26      	Fri Sep 30 14:14:29 2022	superseded     	carto-1.42.10-beta	2022.9.28  	Upgrade complete
27      	Fri Sep 30 14:37:41 2022	superseded     	carto-1.42.10-beta	2022.9.28  	Upgrade complete
28      	Fri Sep 30 15:07:06 2022	pending-upgrade	carto-1.42.10-beta	2022.9.28  	Preparing upgrade
29      	Tue Oct  4 10:58:22 2022	deployed       	carto-1.42.10-beta	2022.9.28  	Rollback to 27
```
Now you can run the upgrade operation again

### 413 Request Entity Too Large

You are trying to make a POST request to the SQL Api with a large payload. Please see the following considerations:

  - By default, we support a payload up to 10Mb. If you need a higher payload size, please see [how to parametrize nginx](#parametrize-router-nginx).
￼
  - If your payload is lower than 10Mb, probably the error code is returned by a service in a higher layer than the Carto Selfhosted environment. Please upload your service configuration to be able to manage higher requests.

  If you have an Ingress Nginx, you have to add the following kubernetes annotation.
￼
  ```diff
  router:
    ingress:
      enabled: true
      tls: true
      annotations:
+       nginx.ingress.kubernetes.io/proxy-body-size: "10m"
      ingressClassName: nginx
  ```