## Traffic Split

This resource allows users to incrementally direct percentages of traffic
between various services. It will be used by *clients* such as ingress
controllers or service mesh sidecars to split the outgoing traffic to different
destinations.

Integrations can use this resource to orchestrate canary releases for new
versions of software. The resource itself is not a complete solution as there
must be some kind of controller managing the traffic shifting over time.
Weighting traffic between various services is also more generally useful than
driving canary releases.

The resource is associated with a *root* service. This is referenced via
`spec.service`. The `spec.service` name is the FQDN that applications will use
to communicate. For any *clients* that are not forwarding their traffic through
a proxy that implements this proposal, the standard Kubernetes service
configuration would continue to operate.

Implementations will weight outgoing traffic between the services referenced by
`spec.backends`. Each backend is a Kubernetes service that potentially has a
different selector and type.

## Specification

```yaml
apiVersion: split.smi-spec.io/v1alpha1
kind: TrafficSplit
metadata:
  name: my-weights
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

### Ports

Kubernetes services can have multiple ports. This specification does *not*
include ports. Services define these themselves and the duplication becomes
extra overhead for users with the potential of misconfiguration. There are some
edge cases to be aware of.

There *must* be a match between a port on the *root* service and a port on every
destination backend service. If they do not match, the backend service is not
included and will not receive traffic.

Mapping between `port` and `targetPort` occurs on each backend service
individually. This allows for new versions of applications to change the ports
they listen on and matches the existing implementation of Services.

It is recommended that implementations issue an event when the configuration is
incorrect. This mis-configuration can be detected as part of an admission
controller.

```yaml
kind: Service
apiVersion: v1
metadata:
  name: birds
spec:
  selector:
    app: birds
  ports:
  - name: grpc
    port: 8080
  - name: rest
    port: 9090
---
kind: Service
apiVersion: v1
metadata:
  name: blue-birds
spec:
  selector:
    app: birds
    color: blue
  ports:
  - name: grpc
    port: 8080
  - name: rest
    port: 9090
---
kind: Service
apiVersion: v1
metadata:
  name: green-birds
spec:
  selector:
    app: birds
    color: green
  ports:
  - name: grpc
    port: 8080
    targetPort: 8081
  - name: rest
    port: 9090
```

This is a valid configuration. Traffic destined for `birds:8080` will select
between 8080 on either `blue-birds` or `green-birds`. When the eventual
destination of traffic is destined for `green-birds`, the `targetPort` is used
and goes to 8081 on the destination pod.

Note: traffic destined for `birds:9090` follows the same guidelines and is in
this example to highlight how multiple ports can work.

```yaml
kind: Service
apiVersion: v1
metadata:
  name: birds
spec:
  selector:
    app: birds
  ports:
  - name: grpc
    port: 8080
---
kind: Service
apiVersion: v1
metadata:
  name: blue-birds
spec:
  selector:
    app: birds
    color: blue
  ports:
  - name: grpc
    port: 1024
---
kind: Service
apiVersion: v1
metadata:
  name: green-birds
spec:
  selector:
    app: birds
    color: green
  ports:
  - name: grpc
    port: 8080
```

This is an invalid configuration. Traffic destined for `birds:8080` will only
ever be forwarded to port 8080 on `green-birds`. As the port is 1024 for
`blue-birds`, there is no way for an implementation to know where the traffic is
eventually destined on a port basis. When configuration such as this is
observed, implementations are recommended to issue an event that notifies users
traffic will not be split for `blue-birds` and visible with
`kubectl describe trafficsplit`.

## Workflow

In this example workflow, the user has previously created the following
resources:

* Deployment named `foobar-v1`, with labels: `app: foobar` and `version: v1`.
* Service named `foobar`, with a selector of `app: foobar`.
* Service named `foobar-v1`, with selectors: `app:foobar` and `version: v1`.
* Clients use the FQDN of `foobar` to communicate.

In order to update an application, the user will perform the following actions:

* Create a new deployment named `foobar-v2`, with labels: `app: foobar`,
  `version: v2`.
* Create a new service named `foobar-v2`, with a selector of: `app: foobar`,
  `version: v2`.
* Create a new traffic split named `foobar-rollout`, it will look like:

    ```yaml
    apiVersion: split.smi-spec.io/v1alpha1
    kind: TrafficSplit
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

    At this point, the SMI implementation does not redirect any traffic to
    `foobar-v2`.

* Once the deployment is healthy, spot check by sending manual requests to the
  `foobar-v2` service. This could be achieved via ingress, port forwarding or
  spinning up integration tests from separate pods.
* When ready, the user increases the weight of `foobar-v2` by updating the
  TrafficSplit resource:

    ```yaml
    apiVersion: split.smi-spec.io/v1alpha1
    kind: TrafficSplit
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

    At this point, the SMI implementation redirects approximately 50% of
    traffic to `foobar-v2`. Note that this is on a per-client basis and not
    global across all requests destined for these backends.

* Verify health metrics and become comfortable with the new version.
* The user decides to let the SMI implementation redirect all traffic to the
  new version by updating the TrafficSplit resource:

    ```yaml
    apiVersion: split.smi-spec.io/v1alpha1
    kind: TrafficSplit
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

## Tradeoffs

* Weights vs percentages - the primary reason for weights is in failure
  situations. For example, if 50% of traffic is being sent to a service that has
  no healthy endpoints - what happens? Weights are simpler to reason about when
  the underlying applications are changing.

* Selectors vs services - it would be possible to have selectors for the
  backends at the TrafficSplit level instead of referential services. The
  referential services are a little bit more flexible. Users will have a
  convenient way to manually test their new versions and implementations will
  have the opportunity to rely on Kuberentes native concepts instead of
  implementing them independently such as endpoints.

* TrafficSplits are not hierarchical - it would be possible to have
  `spec.backends[0].service` refer to a new split. The implementation would
  then be required to resolve this link and reason about weights. By
  making splits non-hierarchical, implementations become simpler and loose the
  possibility of having circular references. It is still possible to build an
  architecture that has nested split definitions, users would need to have a
  secondary proxy to manage that.

* TrafficSplits cannot be self-referential - consider the following definition:

    ```yaml
    apiVersion: split.smi-spec.io/v1alpha1
    kind: TrafficSplit
    metadata:
      name: my-split
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

* Port definitions - this spec uses TrafficSplit to reference services. Services
  have already defined ports, mappings via targetPorts and selectors for the
  destination pods. For this reason, ports are delegated to Services. There are
  some edge cases that arise from this decision. See [ports](#ports) for a more
  in-depth discussion.

## Open Questions

* How should this interact with namespaces? One of the downsides to the current
  workflow is that deployment names end up changing and require a tool such as
  helm or kustomize. By allowing traffic to be split *between* namespaces, it
  would be possible to keep names identical and simply clean up namespaces as
  new versions come out.

## Example implementation

This example implementation is included to illustrate how the `TrafficSplit`
object operates. It is not intended to prescribe a particular implementation.

Assume a `TrafficSplit` object that looks like:

```yaml
    apiVersion: split.smi-spec.io/v1alpha1
    kind: TrafficSplit
    metadata:
      name: my-canary
    spec:
      service: web
      backends:
      - service: web-next
        weight: 100m
      - service: web-current
        weight: 900m
```

When a new `TrafficSplit` object is created, it instantiates the following Kubernetes
objects:

    * Service who's name is the same as `spec.service` in the TrafficSplit (`web`)
    * A Deployment running `nginx` which has labels that match the Service

The nginx layer serves as an HTTP(s) layer which implements the canary. In
particular the nginx config looks like:

```plain
upstream backend {
   server web-next weight=1;
   server web-current weight=9;
}
```

Thus the new `web` service when accessed from a client in Kubernetes will send
10% of it's traffic to `web-next` and 90% of it's traffic to `web`.
