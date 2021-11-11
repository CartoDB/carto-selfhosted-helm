# Contributing Guidelines

Contributions are welcome via GitHub Pull Requests. This document describes the process in order to help get your contribution accepted.

Ant contribution is welcome, it includes new features, bug fixes, and documentation.

## How to Contribute

1. Fork this repository, develop, add your commits and test your changes.
2. Submit a pull request.

***NOTE***: To make the Pull Requests' (PRs) testing and merging process easier, please submit non-related changes in separate PRs.

### Technical Requirements

When submitting a PR make sure that it:
- Must follow [Helm best practices](https://helm.sh/docs/chart_best_practices/).
- Any change to a chart requires a version bump following [semver](https://semver.org/) principles.

### Documentation Requirements

- A chart's `README.md` must include configuration options.
- A chart's `NOTES.txt` must include relevant post-installation information.
- The title of the PR starts with chart name (e.g. `[carto3/<chart-name>]`)

### PR Approval and Release Process

1. Changes are automatically linted and tested.
2. Changes are manually reviewed by team members.
3. When the PR passes all tests, the PR is merged by the reviewer(s) in the GitHub `stable` branch.
4. Then the chart will be pushed to the Helm registry including the recently merged changes and also the latest images and dependencies used by the chart.

***NOTE***: Please note that, in terms of time, may be a slight difference between the appearance of the code in GitHub and the chart in the registry.