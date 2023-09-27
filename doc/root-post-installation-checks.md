### Post-installation checks

In order to verify CARTO Self Hosted was correctly installed and it's functional, we recommend performing the following checks:

1. Check the Helm installation status:
   ```bash
   helm list
   ```

2. Check all pods are up and running:
   ```bash
   kubectl get pods
   ```

3. Sign in to your Self Hosted, create a user and a new organization.

4. Go to the `Connections` page, in the left-hand menu, create a new connection to one of the available providers.

5. Go to the `Data Explorer` page, click on the `Upload` button right next to the `Connections` panel. Import a dataset from a local file.

6. Go back to the `Maps` page, and create a new map.

7. In this new map, add a new layer from a table using the connection created in step 3.

8. Create a new layer from a SQL Query to the same table. You can use a simple query like:
   ```bash
   SELECT * FROM <dataset_name.table_name> LIMIT 100;
   ```

9. Create a new layer from the dataset imported in step 4.

10. Make the map public, copy the sharing URL and open it in a new incognito window.

11. Go back to the `Maps` page, and verify your map appears there and the map thumbnail represents the latest changes you made to the map.