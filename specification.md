## SMI Specification

### Overview

The SMI specification consists of three APIs:

* Mutual TLS - Used for implementing encryption between Pods
* Canary - Used for traffic shapping between versions of a service
* Sidecar - Used for injecting sidecars (eg Monitoring) onto applications.

### Mutual TLS

This resource is used to inject a sidecar that performs Mutual TLS.

This results in every Pod that matches the selector driving their traffic
through TLS with the subject names specified in the spec.

```yaml
apiVersion: v1beta1
kind: TLSConfig
name: my-tls-config
spec:
   # Subject names in the Certificate
   subjectNames:
   - foo
   - bar
   # Selector to identify Pods that have this TLS
   selector:
     matchLabels:
       role: frontend
       stage: production
```

### Canary

This resource allows users to incrementally direct percentages of traffic
between various services. It will be used by *clients* such as ingress
controllers or service mesh sidecars to split the outgoing traffic to different
destinations.

It is associated with a *root* service. This is referenced via `spec.service`.
The `spec.service` name is the FQDN that applications will use to communicate.
For any *clients* that are not forwarding their traffic through a proxy that
implements this proposal, the standard Kubernetes service configuration would
continue to operate.

Implementations will weight outgoing traffic between the services referenced by
`spec.backends`. Each backend is a Kubernetes service that potentially has a
different selector and type.

#### Specification

```yaml
apiVersion: v1beta1
kind: Canary
metadata:
  name: my-canary
spec:
  # The root service that clients use to connect to the destination application.
  service: numbers
  # Services inside the namespace with their own selectors, endpoints and configuration.
  backends:
  - service: one
    # Identical to resources, 1 = 1000m
    weight: 10m
  - service: two
    weight: 100m
  - service: three
    weight: 1500m
```

#### Workflow

An example workflow, given existing:

* Deployment named `foobar-v1`, with labels: `app: foobar` and `version: v1`.
* Service named `foobar`, with a selector of `app: foobar`.
* Service named `foobar-v1`, with selectors: `app:foobar` and `version: v1`.
* Clients use the FQDN of `foobar` to communicate.

For updating an application to a new version:

* Create a new deployment named `foobar-v2`, with labels: `app: foobar`,
  `version: v2`.
* Create a new service named `foobar-v2`, with a selector of: `app: foobar`,
  `version: v2`.
* Create a new canary named `foobar-rollout`, it will look like:

    ```yaml
    apiVersion: v1beta1
    kind: Canary
    metadata:
      name: foobar-rollout
    spec:
      service: foobar
      backends:
      - service: foobar-v1
        weight: 1
      - service: foobar-v2
        weight: 0m
    ```

    At this point, there is no traffic being sent to `foobar-v2`.

* Once the deployment is healthy, spot check by sending manual requests to the
  `foobar-v2` service. This could be achieved via ingress, port forwarding or
  spinning up integration tests from separate pods.
* When ready, increase the weight of `foobar-v2`:

    ```yaml
    apiVersion: v1beta1
    kind: Canary
    metadata:
      name: foobar-rollout
    spec:
      service: foobar
      backends:
      - service: foobar-v1
        weight: 1
      - service: foobar-v2
        weight: 500m
    ```

    At this point, approximately 50% of traffic will be sent to `foobar-v2`.
    Note that this is on a per-client basis and not global across all requests
    destined for these backends.

* Verify health metrics and become comfortable with the new version.
* Send all traffic to the new version:

    ```yaml
    apiVersion: v1beta1
    kind: Canary
    metadata:
      name: foobar-rollout
    spec:
      service: foobar
      backends:
      - service: foobar-v2
        weight: 1
    ```

* Delete the old `foobar-v1` deployment.
* Delete the old `foobar-v1` service.
* Delete `foobar-rollout` as it is no longer needed.

#### Tradeoffs

* Weights vs percentages - the primary reason for weights is in failure
  situations. For example, if 50% of traffic is being sent to a service that has
  no healthy endpoints - what happens? Weights are simpler to reason about when
  the underlying applications are changing.

* Selectors vs services - it would be possible to have selectors for the
  backends at the canary level instead of referential services. The referential
  services are a little bit more flexible. Users will have a convenient way to
  manually test their new versions and implementations will have the opportunity
  to rely on Kuberentes native concepts instead of implementing them
  independently such as endpoints.

* Canaries are not hierarchical - it would be possible to have
  `spec.backends[0].service` refer to a new canary. The implementation would
  then be required to resolve this link and reason about weights. By
  making canaries non-hierarchical, implementations become simpler and loose he
  possibility of having circular references. It is still possible to build an
  architecture that has nested canary definitions, users would need to have a
  secondary proxy to manage that.

* Canaries cannot be self-referential - consider the following definition:

    ```yaml
    apiVersion: v1beta1
    kind: Canary
    metadata:
      name: my-canary
    spec:
      service: foobar
      backends:
      - service: foobar-next
        weight: 100m
      - service: foobar
        weight: 900m
    ```

    In this example, 90% of traffic would be sent to the `foobar` service. As
    this is a superset that contains multiple versions of an application, it
    becomes challenging for users to reason about where traffic is going.

#### Open Questions

* How should this interact with namespaces? One of the downsides to the current
  workflow is that deployment names end up changing and require a tool such as
  helm or kustomize. By allowing canaries *between* namespaces, it would be
  possible to keep names identical and simply clean up namespaces as new
  versions come out.

### Monitor

The Monitor resource defines a sidecar which is injected alongside the
application to perform HTTP monitoring. The Monitor collects standard HTTP
metrics (status codes, requests / second, latency, etc) and exposes a common
interface using Prometheus metrics.

These metrics can be picked up by a metrics scraper and pushed to either an
in-cluster or in-cloud monitoring endpoint.

```yaml
apiVersion: v1beta1
kind: Monitor
name: my-monitor
spec:
  # The monitor sidecar is added to Pods matching these labels
  selector:
    matchLabels:
      role: frontend
      stage: production
  # These labels are applied to the prometheus metrics streams.
  metricLabels:
    team: my-team
    app: my-server
    region: us-east
```
