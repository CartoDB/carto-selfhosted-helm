# CARTO Self-hosted Helm Chart - Claude Code Guidelines

## Project Overview

This repository contains the Helm chart for deploying CARTO Self-hosted on Kubernetes. The chart supports multiple cloud providers (GCP, AWS, Azure) and includes 18 microservice components.

**Key Facts**:
- Chart version: See `chart/Chart.yaml`
- Parameters: 1,694+ documented in `chart/values.yaml`
- Components: accounts-www, maps-api, workspace-api, sql-worker, import-api, etc.
- Documentation: Auto-generated with helm-readme-generator (CI/CD enforced)

## Repository Cloning Convention

**IMPORTANT**: Always check `~/vscode` first before cloning any repository.

### Rule
When cloning CARTO repositories (or any repository), always check if the directory already exists in `~/vscode` to avoid duplicate clones and preserve local changes.

### Correct Pattern

```bash
# Check if repository exists before cloning
if [ ! -d "$HOME/vscode/gitbook-documentation" ]; then
  echo "Repository not found, cloning..."
  gh repo clone CartoDB/gitbook-documentation $HOME/vscode/gitbook-documentation
else
  echo "Repository already exists, pulling latest..."
  cd $HOME/vscode/gitbook-documentation
  git pull origin main
fi
```

### Incorrect Pattern (Don't Do This)

```bash
# DON'T: Clone without checking first
gh repo clone CartoDB/gitbook-documentation $HOME/vscode/gitbook-documentation
```

### Benefits
- ✅ Avoids duplicate repository clones
- ✅ Preserves local changes and work in progress
- ✅ Faster (no re-download if already exists)
- ✅ Consistent location across all projects
- ✅ Prevents git conflicts from multiple clones

### Common Repositories

```bash
# GitBook documentation
~/vscode/gitbook-documentation

# Infrastructure tools and examples
~/vscode/infrastructure-tools

# Helm chart (this repo)
~/vscode/carto-selfhosted-helm
```

## Chart Structure

```
chart/
├── Chart.yaml                 # Chart metadata
├── values.yaml                # Default values (1,694+ parameters)
├── README.md                  # Auto-generated parameter reference (474KB)
├── templates/                 # 104 YAML template files
│   ├── _helpers.tpl           # Template helper functions (1,455 lines)
│   ├── deployments/           # Service deployments
│   ├── configmaps/            # Configuration
│   └── services/              # Service definitions
└── docs/                      # Customization guides
    └── customizations-examples/  # YAML examples
```

## Documentation Philosophy

### Auto-Generated Content
- **chart/README.md**: Auto-generated from `values.yaml` using helm-readme-generator
- **CI/CD enforced**: Workflow fails if manual edits made to README
- **Source of truth**: `values.yaml` with `## @param` and `## @section` annotations

### Manual Documentation
- **docs/** folder: Customization guides and examples
- **examples/helm/**: Platform-specific deployment examples (to be generated)

### GitBook Documentation
- **Public-facing**: https://docs.carto.com
- **Repository**: CartoDB/gitbook-documentation
- **Structure**: `carto-self-hosted/` directory
- **Integration**: Reference section links to chart README on GitHub (doesn't duplicate)

## Workflow Patterns

### Committing Changes
Only commit when explicitly requested by the user. When creating commits:

1. **Check git status** first
2. **Stage relevant files** only
3. **Write clear commit message** explaining changes
4. **Never commit secrets** or sensitive data

### Creating Pull Requests
When requested to create a PR:

1. **Create descriptive branch** name (e.g., `docs/helm-reference-initial`)
2. **Use gh pr create** with comprehensive description
3. **Add labels**: `documentation`, `auto-generated`, `needs-review`
4. **Include checklist** for reviewers
5. **Never auto-merge** - always require human review

### Validation
Before committing YAML examples:

```bash
# Validate with helm template
helm template carto chart/ -f examples/helm/path/to/file.yaml > /dev/null

# Check exit code
if [ $? -eq 0 ]; then
  echo "✓ Valid YAML"
else
  echo "✗ Validation failed"
fi
```

## Security Best Practices

### Never Include
- Actual credentials or API keys
- Service account keys
- Database passwords
- OAuth secrets
- Sensitive customer data

### Always Use
- `# CHANGE THIS` markers for user-specific values
- Placeholder values (e.g., `my-company-carto-imports`)
- Secret references (e.g., `valueFrom: secretKeyRef`)

## Related Projects

### Infrastructure Tools
**Location**: `~/vscode/infrastructure-tools/scripts/self-hosted/carto/helm/`
**Contains**: Example customization YAML files for GCP/AWS
**Use**: Reference for creating new examples

### GitBook Documentation
**Location**: `~/vscode/gitbook-documentation/`
**Contains**: Public-facing documentation
**Structure**: `carto-self-hosted/` (overview, guides, maintenance)

## Automation

### GitHub Actions
- **Workflow**: `.github/workflows/generate-reference-docs.yml` (planned)
- **Trigger**: Push to main when chart files change
- **Action**: Generate/update reference documentation
- **Output**: PR to gitbook-documentation

### Claude Code Integration
- **Model**: Sonnet 4.5
- **Max turns**: 10
- **Timeout**: 25 minutes
- **Tools**: Read, Write, Bash, Grep, Glob
- **Cost**: ~$2-8 per run

## Common Tasks

### Adding New Example
1. Create YAML file in `examples/helm/<category>/`
2. Add comprehensive inline comments
3. Include prerequisites section
4. Add architecture notes
5. Validate with `helm template`
6. Commit with descriptive message

### Updating Documentation
1. Modify `values.yaml` with `## @param` annotations
2. CI/CD auto-generates chart/README.md
3. Update relevant examples if needed
4. Create PR with changes

### Testing Locally
```bash
# Lint the chart
helm lint chart/

# Template with custom values
helm template carto chart/ -f my-values.yaml

# Dry-run installation
helm install --dry-run --debug carto chart/ -f my-values.yaml
```

## Reference Materials

### Official Documentation
- **Helm Chart Best Practices**: https://helm.sh/docs/chart_best_practices/
- **Bitnami Chart Examples**: Reference for documentation style

### CARTO Documentation
- **Public Docs**: https://docs.carto.com/carto-self-hosted
- **Helm Guide**: https://docs.carto.com/carto-self-hosted/deployment-guides/orchestrated-container-deployment

### Project Documentation
- **Planning**: `/tmp/projects/carto-helm-reference-docs/`
- **Work Plan**: See project README for implementation details

---

**Last Updated**: 2025-10-31
**Maintained By**: CARTO Self-hosted Team
