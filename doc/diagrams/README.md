# CARTO Selfhosted Architecture Diagrams

POC for automated architecture diagram generation from Helm charts.

## Quick Start

```bash
cd docs/diagrams

# Install dependencies
./generate.sh --install

# Generate using KubeDiagrams (parses Helm chart automatically)
./generate.sh kubediagrams

# Generate using Mingrammer (manual Python script)
./generate.sh mingrammer

# Generate both
./generate.sh all
```

## Methods Compared

| Method | Automation | Accuracy | Customization |
|--------|------------|----------|---------------|
| **KubeDiagrams** | High (parses chart) | High (from manifests) | Limited |
| **Mingrammer** | Manual (Python script) | Depends on maintenance | Full control |

## Generated Diagrams

| File | Method | Description |
|------|--------|-------------|
| `carto_selfhosted_kubediagrams.png` | KubeDiagrams | Auto-generated from Helm chart |
| `carto_selfhosted.png` | Mingrammer | Manually crafted diagram |

## Files

| File | Purpose |
|------|---------|
| `generate.sh` | Local execution script |
| `generate_architecture.py` | Mingrammer Python script |
| `requirements.txt` | Python dependencies |

## POC Evaluation

- [ ] Compare KubeDiagrams vs Mingrammer output quality
- [ ] Evaluate accuracy of auto-generated diagrams
- [ ] Test with different chart configurations
- [ ] Assess maintainability of each approach
