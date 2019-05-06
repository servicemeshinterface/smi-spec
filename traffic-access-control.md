## Traffic Access Control

This set of resources allows users to define access control policy for their
applications. It is the *authorization* side of the picture. Authentication
should already be handled by the underlying implementation and surfaced through
a subject.

Access control in this specification is *additive*, all traffic is denied by
default. See [tradeoffs](#tradeoffs) for a longer discussion about why.

## Specification

### TrafficTarget

A `TrafficTarget` associates a set of traffic definitions (rules) with a set of
pods. With an accompanying [IdentityBinding](#IdentityBinding), access can be
granted to traffic that matches the rules.

This object defines access control on a pod basis. The selector matches across
labels in the current namespace. This is either directly with `matchLabels` or
as an expression with `matchExpressions`.

Rules are [traffic specs](traffic-specs.md) that define what traffic for
specific protocols would look like. The kind can be different depending on what
traffic a target is serving. In the following examples, `HTTPRoutes` is used for
applications serving HTTP based traffic.

To understand how this all fits together, first define the routes for some
traffic.

```yaml
apiVersion: v1beta1
kind: HTTPRoutes
metadata:
  name: the-routes
matches:
- name: metrics
  pathRegex: "/metrics"
  methods:
  - GET
- name: everything
  pathRegex: ".*"
  methods: ["*"]
```

For this definition, there are two routes: metrics and everything. It is a
common use case to restrict access to `/metrics` to only be scraped by
Prometheus. To define the target for this traffic, it takes a `TrafficTarget`.

```yaml
kind: TrafficTarget
apiVersion: access.smi-spec.io/v1alpha1
metadata:
  name: path-specific
  namespace: default
selector:
  matchLabels:
    app: foo
port: 8080
rules:
- kind: HTTPRoutes
  name: the-routes
  matches:
  - metrics
```

This example selects all the pods with `app: foo` as a label. For traffic
destined to port 8080 on these pods, `/metrics` is allowed. The `matches` field
is optional and if omitted, a rule is valid for all the matches in a traffic
spec (a OR relationship).

Note: access control is *always* enforced on the *server* side of a connection
(or the target). It is up to implementations to decide whether they would also
like to enforce access control on the *client* (or source) side of the
connection as well.

### IdentityBinding

A `IdentityBinding` grants access for a specific identity to the rules in a
TrafficTarget. It holds a list of subjects (service accounts for now) and a
reference to the traffic target defining what has been granted.

```yaml
kind: IdentityBinding
apiVersion: access.smi-spec.io/v1alpha1
metadata:
  name: account-specific
  namespace: default
subjects:
- kind: ServiceAccount
  name: bar
  namespace: default
targetRef:
  kind: TrafficTarget
  name: path-specific
```

This example grants the ability to access the `/metrics` route to any client
providing the identity `bar`, based on a ServiceAccount.

As access control is additive, it is important to provide definitions that allow
non-authenticated traffic access. Imagine rolling a service mesh out
incrementally. Traffic should not, necessarily, be blocked if a client is
unauthenticated. In this world, groups are important as a source of
identity.

```yaml
kind: IdentityBinding
apiVersion: access.smi-spec.io/v1alpha1
metadata:
  name: account-specific
  namespace: default
subjects:
- kind: Group
  name: system:unauthenticated
roleRef:
  kind: TrafficTarget
  name: path-specific
```

This example allows any unauthenticated client access to the rules defined in
the `path-specific` TrafficTarget. Groups are more flexible than just
unauthenticated users. Kubernetes defines many groups by default,
`system:unauthenticated` just happens to be one of these.

### ClusterTrafficTarget

A `ClusterTrafficTarget` allows policy to be applied to targets that live in
multiple namespaces. This is primarily useful to system wide endpoints such as
metrics or health checks.

```yaml
kind: ClusterTrafficTarget
apiVersion: v1beta1
metadata:
  name: metrics-scrape
selector:
  matchExpressions:
  - !protected
port: 8080
rules:
- kind: HTTPRoutes
  name: the-routes
  namespace: prometheus
  matches:
  - metrics
```

This example uses the `HTTPRoutes` definition from
[TrafficTarget](#TrafficTarget) and matches all pods that do *not* contain the
protected label.

### ClusterIdentityBinding

A `ClusterIdentityBinding` grants access for a specific identity, originating in
a specific namespace, to a ClusterTrafficTarget associated with pods in any
namespace.

```yaml
kind: ClusterIdentityBinding
apiVersion: v1beta1
metadata:
  name: metrics-scrape
  namespace: default
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: prometheus
targetRef:
  kind: ClusterTrafficTarget
  name: metrics-scrape
```

Continuing with the Prometheus example from above, it is possible to have a
IdentityBinding that grants a specific system service access to an endpoint on
every pod in the cluster.

Combined with groups, these identity bindings allow users to provide default
allow-all policies.

## Example Implementation

TODO ...

## Tradeoffs

* Additive policy - policy that denies instead of only allows is valuable
  sometimes. Unfortunately, it makes it extremely difficult to reason about what
  is allowed or denied in a configuration.

* Resources vs selectors - it would be possible to reference concrete resources
  such as a deployment instead of selecting across pods.
  * As this access control is on the destination (server) side, implicitly
    matching pods via their ownership becomes a little confusing to users.
  * Referencing concrete resources complicates canary rollouts as it is
    recommended to use multiple deployments to implement a canary rollout.
  * With access control being additive, object references are difficult to use
    when creating allow all policies and break down quickly in this
    environment.

## Out of scope

* Egress policy - TrafficTarget does *not* allow for the possibility of egress
  access control as it selects specific pods and not hostnames. Another object
  will need to be created to manage this use case.

* Ingress policy - assuming clients present the correct identity, this *should*
  work for some kind of ingress. Unfortunately, it does not cover many of the
  common use cases (filtering by hostname) and will need to be expanded to cover
  this use case.

* Other types of policy - having policy around retries, timeouts and rate limits
  would be great. This specific object only manages access control. As policy
  for these examples would be HTTP specific, there needs to be a HTTP specific
  policy object created.

* Other types of identity - there is room to expand the `kind` accepted for
  subjects in IdentityBinding to other types of identity. This needs further
  definition to explain use cases and implementation.

## Open Questions

* Why include namespace in the reference *and* role? Is there any reason a user
  would create a role in one namespace that references another?

* Namespaces should *not* be possible to define on `TrafficRole` for resource
  references but are required for `ClusterTrafficRole`. Is it okay only allow
  this key in `ClusterTrafficRole` references?

* I'm not sure `kind: pod` and `name: *` is the best solution for generic allow
  policies. Is there a better way to do it? `kind: *` feels wrong as well.
