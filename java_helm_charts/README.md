## Commands to Verify or Deploy

# Validate chart syntax
helm lint ./java-helm-charts

# Dry run (render templates without applying)
helm install java-app ./java-helm-charts --dry-run --debug

# Deploy to a namespace (creates if not exists)
helm install java-app ./java-helm-charts -n production --create-namespace

# View generated manifests
helm template java-app ./java-helm-charts

# Upgrade release
helm upgrade java-app ./java-helm-charts -f values.yaml -n production