# Replicated


## Manually generate a new release

```bash
#1. Package the application
helm dependency update chart/ && \
helm package chart/ && \
cp carto-*.tgz manifests/

replicated release create --auto --app carto --token <your_token>
```