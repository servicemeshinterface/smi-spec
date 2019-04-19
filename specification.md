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

### Traffic Policy

This resource allows users to define the authorization policy between
applications and clients.

There are two high level concepts, `TrafficRole` and `TrafficRoleBinding`. A
`TrafficRole` describes a resource that will be receiving requests and what
traffic can be issued to that resource. As an example, a `TrafficRole` could be
configured to reference a pod and only allow `GET` requests to a specific
endpoint on that service.

The `TrafficRoleBinding` associates a client's identity with a `TrafficRole`.
This client can then issue requests to the configured resource using the allowed
paths and methods. The design of Kubernetes RBAC has been heavily borrowed from.

TrafficRoles are designed to work in an additive fashion and all traffic is
denied by default. See [tradeoffs](#policy-tradeoffs) for more details on that
decision.

#### Specification

#### TrafficRole

A `TrafficRole` contains a list of rules that have: resources, methods and
paths. These work in concert to define what an authorized client can request.

Resources reference Kubernetes objects. These can be anything such as
deployments, services and pods. The resource concretely defines the resource
that will be serving the traffic itself either as a group (ex. deployment) or a
pod itself.

The full list of resources that can be referenced is:

* pods
* replicationscontrollers
* services
* daemonsets
* deployments
* replicasets
* statefulets
* jobs

Methods describe the HTTP method that is allowed for the referenced resource.
This is limited to existing HTTP methods. It is possible to use `*` to allow any
value instead of enumerating them all.

Paths describe the HTTP path that a referenced resource serves. The path is a
regex and is anchored (`^`) to the start of the URI. See [use cases]
(#policy-use-cases) for some examples about how these can be generated
automatically without user interaction.

Bringing everything together, an example specification:

```yaml
kind: TrafficRole
apiVersion: v1beta1
metadata:
  name: path-specific
  namespace: default
rules:
- resources:
  - name: foo
    kind: Deployment
  methods:
  - GET
  paths:
  - '/authors/\d+'
```

This specification can be used to grant access to the `foo` deployment for `GET`
requests to paths like `/authors/1234`. An accompanying `TrafficRoleBinding`
would allow authorized clients to request this path.

Note that `namespace` is *not* part of the resource references. The resources
must be within the same namespace that a `TrafficRole` resides in. See
[tradeoffs](#policy-tradeoffs) for a discussion on why this is.

While it is convenient to be extremely specific, most policies will be a little
bit more general. The following `TrafficRole` can be used to grant access to the
`foo` service and by association the endpoints that service selects. Any method
and path would be accessible.

```yaml
kind: TrafficRole
apiVersion: v1beta1
metadata:
  name: service-specific
  namespace: default
rules:
- resources:
  - name: foo
    kind: Service
  methods: ["*"]
  paths: ["*"]
```

As roles are additive, policies that can allow all traffic are helpful for
testing environments or super users. To grant access to anything in a namespace,
`*` can be used in combination with `kind`. The other keys are optional in this
example.

```yaml
kind: TrafficRole
apiVersion: v1beta1
metadata:
  name: service-specific
  namespace: default
rules:
- resources:
  - name: "*"
    kind: Pod
  methods: ["*"]
  paths: ["*"]
```

#### TrafficRoleBinding

A `TrafficRoleBinding` grants the permissions defined in a `TrafficRole` to a
specified identity. It holds a list of subjects (service accounts, deployments)
and a reference to the role being granted.

The following binding grants the `path-specific` role to pods contained within
the deployment `bar` in the `default` namespace. Assuming the `path-specific`
definition from above, these pods will be authorized to issue `GET` requests to
the `foo` deployment with paths matching the `/authors/\d+` regex.

```yaml
kind: TrafficRoleBinding
apiVersion: v1beta1
metadata:
  name: account-specific
  namespace: default
subjects:
- kind: Deployment
  name: bar
  namespace: default
roleRef:
  kind: TrafficRole
  name: path-specific
```

Note: this specification defines that policy is *always* enforced on the
*server* side of a connection. It is up to implementations to decide whether
they would also like to enforce this policy on the *client* side of the
connection as well.

Bindings reference subjects that can be defined based on identity. This allows
for references to be more than just groups of pods. In this example, a binding
is against a service account.

```yaml
kind: TrafficRoleBinding
apiVersion: v1beta1
metadata:
  name: account-specific
  namespace: default
subjects:
- kind: ServiceAccount
  name: foo-account
  namespace: default
roleRef:
  kind: TrafficRole
  name: path-specific
```

Implementations and cluster administrators can provide some default policy as
[ClusterTrafficRole](#clustertrafficrole). These can be bound to specific
namespaces and will only be valid for that specific namespace. In this example,
a `ClusterTrafficRole` that grants access to `/health` is bound only inside the
`default` namespace for the pod `foobar`.

```yaml
kind: TrafficRoleBinding
apiVersion: v1beta1
metadata:
  name: health-check
  namespace: default
subjects:
- kind: Pod
  name: foobar
roleRef:
  kind: ClusterTrafficRole
  name: health-check
```

#### ClusterTrafficRole

Roles can be defined cluster-wide with `ClusterTrafficRole`. These roles can
grant access to applications in specific namespaces or across all namespaces and
are particularly useful for providing sane default policy.

The following `ClusterTrafficRole` can be used to grant access to `/health`
endpoints.

```yaml
kind: ClusterTrafficRole
apiVersion: v1beta1
metadata:
  name: health-check
rules:
- resources:
  - name: "*"
    kind: Pod
  methods:
  - GET
  paths:
  - '/health'
```

A `ClusterTrafficRole` can also be used as a default allow policy.

```yaml
kind: ClusterTrafficRole
apiVersion: v1beta1
metadata:
  name: default-allow
rules:
- resources:
  - name: "*"
    kind: Pod
  methods: ["*"]
  paths: ["*"]
```

#### ClusterTrafficRoleBinding

The following `ClusterTrafficRoleBinding` will grant access every node in the
cluster to request the `/health` endpoint served by pods in any namespace.

```yaml
kind: ClusterTrafficRoleBinding
apiVersion: v1beta1
metadata:
  name: default-allow
subjects:
- name: *
  kind: Node
roleRef:
  kind: ClusterTrafficRole
  name: health-check
```

To grant the pod `root` running in any namespace access to every pod serving any
endpoint in any namespace, it would be possible to do:

```yaml
kind: ClusterTrafficRoleBinding
apiVersion: v1beta1
metadata:
  name: default-allow
subjects:
- name: root
  kind: Pod
roleRef:
  kind: ClusterTrafficRole
  name: default-allow
```

#### Workflow

#### Use Cases {#policy-use-cases}

##### OpenAPI/Swagger

Many REST applications provide OpenAPI definitions for their endpoints,
operations and authentication methods. Consuming these definitions and
generating policy automatically allows developers and organizations keep the
definition of their policy in a single location. A given specification can be
used to create `TrafficRole` and `TrafficRoleBinding` objects as part of a CI/CD
workflow.

TODO - specification mapping

#### Tradeoffs {#policy-tradeoffs}

* Additive policy - policy that denies instead of only allows is valuable
  sometimes. Unfortunately, it makes it extremely difficult to reason about what
  is allowed or denied in a configuration.
* It would be possible to support `kind: Namespace`. This ends up having some
  special casing as to references and doesn't cover all cases. Instead, there
  has been a conscious decision to allow `*` kinds instead of supporting
  non-namespaced resources (for example, namespaces). This solves the same user
  goal and is slightly more flexible.
* Namespaces are explicitly left out of the resource reference (`namespace:
  foobar`). This is because the reference could be used to point to a resource
  in a different namespace that a user might not have permissions to access or
  define.It also ends up being somewhat redundant as `namespace: foobar` is
  defined by the location of the resource itself.

#### Out of scope

* Egress policy - while this specification allows for the possibility of
  defining egress configuration, this functionality is currently out of scope.
* Non-HTTP traffic - this specification will need to be expanded to support
  traffic such as Kafka or MySQL.

#### Open Questions

* Why include namespace in the reference *and* role? Is there any reason a user
  would create a role in one namespace that references another?
* Namespaces should *not* be possible to define on `TrafficRole` for resource
  references but are required for `ClusterTrafficRole`. Is it okay only allow
  this key in `ClusterTrafficRole` references?
* I'm not sure `kind: pod` and `name: *` is the best solution for generic allow
  policies. Is there a better way to do it? `kind: *` feels wrong as well.

### Traffic Split

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

#### Specification

```yaml
apiVersion: v1beta1
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
* Create a new traffic split named `foobar-rollout`, it will look like:

    ```yaml
    apiVersion: v1beta1
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

    At this point, there is no traffic being sent to `foobar-v2`.

* Once the deployment is healthy, spot check by sending manual requests to the
  `foobar-v2` service. This could be achieved via ingress, port forwarding or
  spinning up integration tests from separate pods.
* When ready, increase the weight of `foobar-v2`:

    ```yaml
    apiVersion: v1beta1
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

    At this point, approximately 50% of traffic will be sent to `foobar-v2`.
    Note that this is on a per-client basis and not global across all requests
    destined for these backends.

* Verify health metrics and become comfortable with the new version.
* Send all traffic to the new version:

    ```yaml
    apiVersion: v1beta1
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

#### Tradeoffs

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
    apiVersion: v1beta1
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

#### Open Questions

* How should this interact with namespaces? One of the downsides to the current
  workflow is that deployment names end up changing and require a tool such as
  helm or kustomize. By allowing traffic to be split *between* namespaces, it
  would be possible to keep names identical and simply clean up namespaces as
  new versions come out.

#### Example implementation

This example implementation is included to illustrate how the `Canary` object
operates. It is not intended to prescribe a particular implementation.

Assume a `Canary` object that looks like:

```yaml
    apiVersion: v1beta1
    kind: Canary
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

When a new `Canary` object is created, it instantiates the following Kubernetes objects:

    * Service who's name is the same as `spec.service` in the Canary (`web`)
    * A Deployment running `nginx` which has labels that match the Service

The nginx layer serves as an HTTP(s) layer which implements the canary. In particular
the nginx config looks like:

```plain
upstream backend {
   server web-next weight=1;
   server web-current weight=9;
}
```

Thus the new `web` service when accessed from a client in Kubernetes will send
10% of it's traffic to `web-next` and 90% of it's traffic to `web`.

### Traffic Metrics

This resource provides a common integration point for tools that can benefit by
consuming metrics related to HTTP traffic. It follows the pattern of
`metrics.k8s.io` for instantaneous metrics that can be consumed by CLI tooling,
HPA scaling or automating canary updates.

As many of the implementations for this will be storing metrics in Prometheus,
it would be possible to just standardize on metric/label naming. This,
unfortunately, makes integration more difficult as every integration will need
to write their own Prometheus queries. For more details, see the
[tradeoffs](#tradeoffs) section.

Metrics are associated with a *resource*. These can be pods as well as higher
level concepts such as namespaces, deployments or services. All metrics are
associated with the Kubernetes resource that is either generating or serving
the measured traffic.

Pods are the most granular resource that metrics can be associated with. It is
common to look at aggregates of pods to reason about the traffic as a whole for
an application. Imagine looking at the aggregated success rate for a deployment
during canary rollouts. All resources that contain pods are aggregates of the
metrics contained within the pods. These are calculated by the implementation
itself. It is *not* possible to arbitrarily create groupings of pods to
aggregate metrics.

In addition to resources, metrics are scoped to *edges*. An edge represents
either the source of traffic or its destination. These edges restrict the
metrics to only the traffic between the `resource` and `edge.resource`.
`edge.resource` can either be general or specific. In the most general case, a
blank `edge.resource` would have metrics for all the traffic received by
`resource`.

Edges are only visible between two resources that have exchanged traffic. They
are not declarative, all traffic is monitored and can only be queried in
association with a specific resource. The list of edges for a specified resource
can be returned, it is not possible to query specific, unique edges.

Being able to query for these metrics is an important piece of the puzzle. There
are two main ways to query the API for metrics:

* The supported resources (pods, namespaces, ...) are available as part of an
  `APIResourceList`. This provides both `list` and `get` support.
* For supported resources, it is possible to use a label selector as a filter.
* A sub-resource allows querying for all the edges associated with a specific
  resource.

#### Specification

The core resource is `TrafficMetrics`. It references a `resource`, has an `edge`
and surfaces latency percentiles and request volume.

```yaml
apiVersion: traffic.metrics.k8s.io/v1beta1
kind: TrafficMetrics
# See ObjectReference v1 core for full spec
resource:
  name: foo-775b9cbd88-ntxsl
  namespace: foobar
  kind: Pod
edge:
  direction: to
  resource:
    name: baz-577db7d977-lsk2q
    namespace: foobar
    kind: Pod
timestamp: 2019-04-08T22:25:55Z
window: 30s
metrics:
- name: p99_response_latency
  unit: seconds
  value: 10m
- name: p90_response_latency
  unit: seconds
  value: 10m
- name: p50_response_latency
  unit: seconds
  value: 10m
- name: success_count
  value: 100
- name: failure_count
  value: 100
```

##### Edge

In this example, the metrics are observed *at* the `foo-775b9cbd88-ntxsl` pod
and represent all the traffic *to* the `baz-577db7d977-lsk2q` pod. This
effectively shows the traffic originating from `foo-775b9cbd88-ntxsl` and can be
used to define a DAG of resource dependencies.

```yaml
resource:
  name: foo-775b9cbd88-ntxsl
  namespace: foobar
  kind: Pod
edge:
  direction: to
  resource:
    name: baz-577db7d977-lsk2q
    namespace: foobar
    kind: Pod
```

Alternatively, edges can also be observed *at* the `foo-775b9cbd88-ntxsl` pod
and represent all the traffic *from* the `bar-5b48b5fb9c-7rw27` pod. This
effectively shows how `foo-775b9cbd88-ntxsl` is handling the traffic destined
for it from a specific source. Just like `to`, this data can be used to define a
DAG of resource dependencies.

```yaml
resource:
  name: foo-775b9cbd88-ntxsl
  namespace: foobar
  kind: Pod
edge:
  direction: from
  resource:
    name: bar-5b48b5fb9c-7rw27
    namespace: foobar
    kind: Pod
```

Finally, `resource` can be as general or specific as desired. For example, with
a `direction` of `to` and an empty `resource`, the metrics are observed *at*
the `foo-775b9cbd88-ntxsl` pod and represent all traffic *to* the
`foo-775b9cbd88-ntxsl` pod.

```yaml
resource:
  name: foo-775b9cbd88-ntxsl
  namespace: foobar
  kind: Pod
edge:
  direction: to
  resource: {}
```

Note: `resource` could also contain only a namespace to select any traffic from
that namespace or only `kind` to select specific types of incoming traffic.

Note: there is no requirement that metrics are actually being collected for
resources selected by edges. As metrics are always observed *at* `resource`, it
is possible to construct these entirely from the resource.

##### TrafficMetricsList

There are three different ways to get a TrafficMetricsList:

* Requesting a specific `kind` such as pods or namespaces.

    ```yaml
    apiVersion: traffic.metrics.k8s.io/v1beta1
    kind: TrafficMetricsList
    resource:
      kind: Pod
    items:
    ...
    ```

    Note: the values for `resource` would only be `kind`, `namespace` and
    `apiVersion`.

* Requesting a specific `kind` such as pods and filtering with a label selector:

    ```yaml
    apiVersion: traffic.metrics.k8s.io/v1beta1
    kind: TrafficMetricsList
    resource:
      kind: Pod
    selector:
      matchLabels:
        app: foo
    items:
    ...
    ```

    Note: the label selector does *not* filter the metrics themselves, only the
    items that show up in the list.

* Listing all the edges for a specific resource:

    ```yaml
    apiVersion: traffic.metrics.k8s.io/v1beta1
    kind: TrafficMetricsList
    resource:
      name: foo-775b9cbd88-ntxsl
      namespace: foobar
      kind: Pod
    selector:
      matchLabels:
        app: foo
    items:
    ...
    ```

    Note: this specific list is a sub-resource of `foo-775b9cbd88-ntxsl` from an
    API perspective.

##### Kubernetes API

The `traffic.metrics.k8s.io` API will be exposed via a `APIService`:

```yaml
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1beta1.mesh.metrics.k8s.io
spec:
  group: mesh.metrics.k8s.io
  service:
    name: mesh-metrics
    namespace: default
  version: v1beta1
```

The default response, or requesting `/apis/traffic.metrics.k8s.io/v1beta1/`
would return:

```yaml
apiVersion: v1
kind: APIResourceList
groupVersion: mesh.metrics.k8s.io/v1beta1
resources:
- name: namespaces
  namespaced: false
  kind: TrafficMetrics
  verbs:
  - get
  - list
- name: deployments
  namespaced: true
  kind: TrafficMetrics
  verbs:
  - get
  - list
...
- name: pods
  namespaced: true
  kind: TrafficMetrics
  verbs:
  - get
  - list
```

The full list of resources for this list would be:

* namespaces
* nodes
* pods
* replicationcontrollers
* services
* daemonsets
* deployments
* replicasets
* statefulsets
* jobs

For resource types that contain `pods`, such as `namespaces` and `deployments`,
the metrics are aggregates of the `pods` contained within.

#### Use Cases

##### Top

Like `kubectl top`, a plugin could be written such as `kubectl traffic top` that
shows the traffic metrics for resources.

```bash
$ kubectl traffic top pods
NAME                        SUCCESS      RPS   LATENCY_P99
foo-6846bf6b-gjmvz          100.00%   1.8rps           1ms
bar-f84f44b5b-dk4g9          75.47%   0.9rps           1ms
baz-69c8bb6d5b-gn5rt         86.67%   1.8rps           2ms
```

Implementation of this command would be a simple conversion of the API's
response of a `TrafficMetricsList` into a table for display on the command line
or a dashboard.

##### Canary

In combination with the Canary specification, a controller can:

* Create a new deployment `v2`.
* Add a new canary and service for `v2`.
* Update the canary definition to send some traffic to `v2`.
* Monitor for success rate to drop below 100%. If it does, rollback.
* Update the canary definition to route more traffic.
* Loop until all traffic is on `v2`.

##### Topologies

Following the concept of `kubectl traffic top`, there could also be a
`kubectl traffic topology` command. This could provide ascii graphs of the
topology between applications. Alternative outputs could be graphviz's DOT
language.

```bash
$ kubectl traffic topology deployment
                  +-------------------------------+
                  |                               v
+---------+     +--------+     +---------+      +-------+
| traffic | --> | foo    | --> | bar     | <--> | baz   |
+---------+     +--------+     +---------+      +-------+
```

Implementation of this command would require multiple queries, one to get the
list of all deployments and another to get the edges for each of those
deployments. While this example shows command line usage, it should be
possible dashboards such as Kiali entirely on top of this API.

#### RBAC

* View metrics for all resources and edges.

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: Role
    metadata:
      name: traffic-metrics
    rules:
    - apiGroups:
      - traffic.metrics.k8s.io
      resources: ["*"]
      verbs: ["*"]
    ```

* View only the metrics for edges of pods.

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: Role
    metadata:
      name: traffic-metrics
    rules:
    - apiGroups:
      - traffic.metrics.k8s.io
      resources: ["pods/edges"]
      verbs: ["*"]
    ```

#### Example implementation

This example implementation is included to illustrate how `TrafficMetrics` are
surfaced. It does *not* prescribe a particular implementation. This example also
does not serve as an example of how to consume the metrics provided.

![Metrics Architecture](traffic-metrics-sample/metrics.png)

For this example implementation, metrics are being stored in Prometheus. These
are being scraped [from Envoy](#envoy-mesh) periodically. The only component in
this architecture that is custom is the `Traffic Metrics Shim`. All others do
not require any modification.

The shim maps from Kubernetes native API standards to the Prometheus store which
is an implementation detail of the service mesh. As the shim itself is doing the
mapping, any backend metrics store could be used.

Walking through the request flow:

1. An end user fires off a request to the Kubernetes API Server:

    ```bash
    kubectl get --raw /apis/traffic.metrics.k8s.io/v1beta1/namespaces/default/deployments/
    ```

1. The Kubernetes API server forwards this request to the `Traffic Metrics
Shim`.

1. The shim issues multiple requests to Prometheus. An example for the total
   requests grouped by success and failure would be:

    ```plain
    sum(requests_total{namespace='default',kind='deployment'}) by (name, success)
    ```

    Note: there are multiple queries required here to fetch all the metrics for
    a response.

1. On receiving the responses from Prometheus, the shim converts the values into
   a `TrafficMesh` object for consumption by the end user.

#### Envoy Mesh

![Envoy Mesh](traffic-metrics-sample/mesh.png)

While the mesh itself is outside the scope of this example, it is valuable to
see that piece of the architecture as well. Prometheus has a scrape config that
targets pods with an Envoy sidecar and periodically requests
`/stats?format=prometheus`.

#### Tradeoffs

* APIService - it would be possible to simply be proscriptive of metrics and
  label names for Prometheus, configure many of these responses as recording
  rules and force integrations to query those directly. This feels like it
  increases the bar for metrics stores to change their internal configuration
  around to support this specification. There is also not a multi-tenant story
  for Prometheus series visibility that maps across Kuberenetes RBAC. From the
  other side, consumers of these metrics will have to do discovery of
  Prometheus' location in the cluster and do some kind of queries to surface the
  data that they need.

* Edges - while it is valuable to see all the traffic metrics associated with a
  specific resource, debugging regularly requires understanding the path that
  traffic is taking between specific resources. Additionally, seeing the edges
  opens up a new set of integrations such as topology graphs and more flexible
  canary policy.

* Aggregation - being able to look at metrics across higher level concepts such
  as deployments (imagine tracking v2 of a deployment during a canary rollout).
  These are hard to aggregate without access to the underlying data and so it is
  valuable to access the data pre-aggregated from the API perspective.

* `custom.metrics` vs `metrics` styles - this API groups metrics together by
  resource. The `custom.metrics.k8s.io` API presents a long list of metrics with
  names that suggest the resource. Because the primary use is to fetch a group
  of metrics associated with a resource, this API matches the `metrics.k8s.io`
  style a little bit more.

* Counts - most users will want to see RPS and success rates instead of raw
  counts. As these are trivial to calculate from success/failure counts and
  cover up some important data, counts are being used.

#### Out of scope

* Edge aggregation - it would be valuable to get a resource such as a pod and
  see the edges for other aggregates such as deployments. For now, the queries
  to do this are not defined.
* Label selectors - this API uses label selectors to impact filtering of
  resources and does not use these selectors for the actual metric series. Using
  the selectors against metric series is very valuable, imagine getting
  per-route metrics surfaced.
* Historical data - while this API *could* support delivering historical data,
  it is not called out explicitly right now. The primary use cases currently are
  immediate requirements: how is the canary rollout going? what is my topology?
  what is happening to my application right now?

#### Open Questions

* stddev - the best integration for canary deployments or things like HPA would
  be surfacing the stddev of metrics. Then, monitoring could be +/- outside of
  the last measurements. This API is not particularly well setup to surface
  these numbers and it might not be as useful as they look.
