import yaml

def filter_deployments(file_path, apps):
    with open(file_path, 'r') as file:
        manifests = yaml.safe_load_all(file)
        deployments = [manifest for manifest in manifests if manifest.get('kind') == 'Deployment' and manifest.get('metadata', {}).get('labels', {}).get('app.kubernetes.io/component') in apps]
    return deployments

file_path = 'template.txt'
apps = ['accounts-www', 'import-api']

selected_deployments = filter_deployments(file_path, apps)

# Get only deployment app.kubernetes.io/component and resources section
filtered_deployments = [{k: v for k, v in selected_deployments if k in ['metadata', 'spec']} for deployment in selected_deployments]
print(filtered_deployments)
