---
paths:
  - "chart/templates/_commonChecks.tpl"
  - "chart/templates/preflight.yaml"
  - "chart/templates/support-bundle.yaml"
---

# `_commonChecks.tpl` + preflight/support-bundle — environment checks

This is the [troubleshoot.sh](https://troubleshoot.sh) framework. Both
`preflight.yaml` and `support-bundle.yaml` render a **Kubernetes Secret** whose
`stringData` embeds a troubleshoot.sh spec as a string, discovered by the label
`troubleshoot.sh/kind: preflight` (or `support-bundle`). Both pull their shared
collectors/analyzers from `_commonChecks.tpl`.

- **Preflight** = runs **before** install, **blocks** it on failure. Pre-install,
  the app pods don't exist yet — so preflights can only test the *environment*.
- **Support bundle** = post-hoc **diagnostics**, never blocks. It includes the
  same environment checks *plus* cluster info, namespaced pod logs, and pod-status
  analyzers (CrashLoopBackOff, ImagePullBackOff, Pending, …).

**The engine is one pod.** The main collector
(`carto.replicated.commonChecks.collectors`) launches a `tenant-requirements-check`
pod from the `tenant-requirements-checker` image. An **init container unpacks
secrets/certs from env vars into files** (the `THING__FILE_CONTENT` /
`THING__FILE_PATH` convention; large Postgres CA bundles are chunked into `…_01`,
`…_02`, … to dodge the env-var size limit, then reassembled). The pod runs the
checks and writes a JSON log; the **analyzers read that JSON**.

**The verdict pattern.** `_commonChecks.tpl` builds a dict of
`Validator → [Check names]`, then loops it into one `jsonCompare` analyzer per
check that asserts `…<Validator>.<Check>.status == "passed"`, surfacing the pod's
own `.info` string as the message. Checks in the **optional list** (TomTom,
TravelTime connectivity) emit **`warn` instead of `fail`** so they don't block.
Several validators are **conditional**: the Redis check only exists when
`internalRedis.enabled=false`; certificate checks only when a cert is provided;
feature-flag check only when overrides are set.

**What's actually checked** (environment, blocking unless noted): Postgres
reachability / UTF8 encoding / permissions / version / optional SSL cert; cache
(Redis/Valkey) reachability + multi-DB support + optional TLS; object storage
(GCS/S3/Azure) assets+temp bucket read/write; Google service-account validity
(when not using Workload Identity); egress to CARTO auth, PubSub, GCS, release
channels, image registry (+ optional TomTom/TravelTime); PubSub publish/consume;
feature-flag JSON validity; provided TLS certs. **Cluster-level analyzers** (K8s
version floor, container runtime, supported distribution, minimum CPU/RAM,
Gateway API CRD when `gateway.enabled` — exact thresholds in `_commonChecks.tpl`)
run **only when `replicated.platformDistribution != ""`**.

**To add an environment check:** the actual logic lives in the external
`tenant-requirements-checker` image (it must emit `{Validator:{Check:{status,info}}}`
JSON). In *this* repo you extend the validator/check dict in `_commonChecks.tpl`
(conditionally if needed) and, if the check needs new inputs, add them to the
checker's `customerValues` / `customerSecrets` env blocks (wiring files through
the init-container convention). A support-bundle-only collector is just an extra
`collectors:` entry in `support-bundle.yaml` (+ an analyzer if you want a verdict).

**Gotchas:** a collector with no analyzer collects data nobody reads; the checker
pod holds real secrets, so never let a check echo them into its `.info`;
everything runs in `.Release.Namespace` — **never hardcode a namespace**;
**ingress-only test mode (`onlyRunRouter`) deploys no backends** — account for it
when adding preflights; and `jsonCompare` messages mix two templating layers
(outer Helm `{{ }}` emitting an inner troubleshoot.sh `{{ }}` string) — easy to
mis-escape.
