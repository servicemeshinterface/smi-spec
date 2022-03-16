# Traffic Access Control

**API Group:** access.smi-spec.io

**API Version:** v1alpha4

**Compatible with:** specs.smi-spec.io/v1alpha4

## Specification

This set of resources allows users to define access control policy for their
applications. It is the authorization side of the picture. Authentication should
already be handled by the underlying implementation and surfaced through a subject.

Access control in this specification is additive, all traffic is denied by default.
See [tradeoffs](#tradeoffs) for a longer discussion about why.

### IdentityBinding

An `IdentityBinding` declares the set of identities belonging to a particular workload
for the purposes of policy. At present, Kubernetes does not natively provide any
sort of identity resource outside of `ServiceAccount`. As such, many mesh
implementations have turned to alternative identification schemes for more control
over traffic routign and policy (e.g. SPIFFE, pod selectors, etc). Unfortunately,
these arbitrary identity mechanisms are rarely stored in a machine-accessible
manner. This is the role of the `IdentityBinding` resource.

```yaml
apiVersion: access.smi-spec.io/v1alpha4
kind: IdentityBinding
metadata:
 name: service-a
 namespace: default
spec:
 schemes:
   podLabelSelectors:
     - name: podWorkloads
       matchLabels:
         app: service-a
   spiffeIdentities:
     - "cluster.local/ns/default/sa/service-a"
     - "federated.trustdomain/boundary/boundaryName/identifierType/identifier"
   serviceAccount: service-a
```

#### Resource Design

The `IdentityBinding` resource consists of a set of predefined "schemes", each one
encapsulating some identification mechanism. Each scheme's configuration is OR'd
together with other schemes, allowing cluster operators to compose
a single representation of a service's identity . The set of supported schemes are
maintained by the SMI spec, PRs welcome! Rather than coupling to mesh-specific
implementations, schemes should be based on well-known and documented standards
such as SPIFFE, JWT, Kubernetes pod specs, etc. This allows for more consistent
and predictable behavior across runtime environments. `IdentityBinding` currently
supports 3 schemes:

- Pod Label selector (`podLabelSelectors`)
- SPIFFE (`spiffeIdentities`)
- Service Account (`serviceAccount`)
  - *Note:* The service account specified in this field is implied to exist
  in the `IdentityBinding`'s namespace. If one desires to govern access control
  for services replicated across different namespaces, they should create an
  `IdentityBinding` containing the requisite `ServiceAccount` reference in
  each namespace

The namespace where the `IdentityBinding` is located is also the boundary
for the workloads it applies to. In other words, an `IdentityBinding` resource
in one namespace makes no declaration of identity for workloads in another
namespace. This purpose for this decision is twofold:

1. As a general rule, the ability to modify the identity/policy of workloads
   running in other namespaces is a gross violation of the namespace isolation boundary.
   For multi-tenant Kubernetes clusters, allowing `IdentityBinding` to do this
   would bea non-starter.

2. More practically, Kubernetes RBAC policies most frequently target namespaces
   as access boundaries. Without limiting the scope of `IdentityBinding` to its namespace,
   a bad actor with permissions in one namespace could weaken the access control
   for workloads in another namespace by crafting a malicious `IdentityBinding`.

#### Why a separate resource

At its core, [TrafficTarget](#traffictarget) is a resource that governs
*access control*. Adding the semantic complexities of binding arbitrary identity
to workloads would overcomplicate the `TrafficTarget` manifest and its administration.

### TrafficTarget

A `TrafficTarget` associates a set of traffic definitions (rules) with a
service identity which is allocated to a group of pods.  Access is controlled
via referenced [TrafficSpecs](/apis/traffic-specs/v1alpha4/traffic-specs.md)
and by a list of source service identities (via [`IdentityBinding`](#identitybinding)
or `ServiceAccount`). If a pod which holds the reference service identity makes
a call to the destination on one of the defined routes then access will be
allowed. Any pod which attempts to connect and is not in the defined list of
sources will be denied. Any pod which is in the defined list but attempts to
connect on a route which is not in the list of `TrafficSpecs` will be denied.

Rules are [traffic specs](/apis/traffic-specs/v1alpha4/traffic-specs.md) that
define what traffic for specific protocols would look like. The kind can be
different depending on what traffic a target is serving. In the following
examples, `HTTPRouteGroup` is used for applications serving HTTP based traffic.

A valid `TrafficTarget` must specify a destination, at least one rule, and
at least one source.

To understand how this all fits together, first define the routes for some
traffic.

```yaml
kind: TCPRoute
metadata:
  name: the-routes
spec:
  matches:
    ports:
    - 8080
---
kind: HTTPRouteGroup
metadata:
  name: the-routes
spec:
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
---
kind: TrafficTarget
metadata:
  name: path-specific
  namespace: default
spec:
  destination:
    kind: IdentityBinding
    group: access.smi-spec.io
    name: service-a
    namespace: default
  rules:
  - kind: TCPRoute
    name: the-routes
  - kind: HTTPRouteGroup
    name: the-routes
    matches:
    - metrics
  sources:
  - kind: IdentityBinding
    group: access.smi-spec.io
    name: prometheus
    namespace: default
```

This example selects all the pods which have the `service-a` `ServiceAccount`.
Traffic destined on a path `/metrics` is allowed. The `matches` field is
optional and if omitted, a rule is valid for all the matches in a traffic spec
(a OR relationship).  It is possible for a service to expose multiple ports,
the TCPRoute/UDPRoute `matches.ports` field allows the user to specify
specifically which port traffic should be allowed on.
The `matches.ports` is an optional element, if not specified, traffic
will be allowed to all ports on the destination service.

Allowing destination traffic should only be possible with permission of the
service owner. Therefore, RBAC rules should be configured to control the pods
which are allowed to assign any `ServiceAccount`s referenced in the `IdentityBinding`
defined in the TrafficTarget destination. Cluster operators should also create the
appropriate RBAC rules to configure limited access for `IdentityBinding` creation.

**Note:** access control is *always* enforced on the *server* side of a
connection (or the target). It is up to implementations to decide whether they
would also like to enforce access control on the *client* (or source) side of
the connection as well.

Source identities which are allowed to connect to the destination is defined in
the sources list.  Only pods which have a `ServiceAccount` which is named in
the sources list are allowed to connect to the destination.

## Example implementation for L7

The following implementation shows four services api, website, payment and
prometheus. It shows how it is possible to write fine grained TrafficTargets
which allow access to be controlled by route and source.

```yaml
kind: TCPRoute
metadata:
  name: api-service-port
spec:
  matches:
    ports:
    - 8080
---
kind: HTTPRouteGroup
metadata:
  name: api-service-routes
spec:
  matches:
  - name: api
    pathRegex: /api
    methods: ["*"]
  - name: metrics
    pathRegex: /metrics
    methods: ["GET"]
---
kind: TrafficTarget
metadata:
  name: api-service-metrics
  namespace: default
spec:
  destination:
    kind: IdentityBinding
    group: access.smi-spec.io
    name: api-service
    namespace: default
  rules:
  - kind: TCPRoute
    name: api-service-port
  - kind: HTTPRouteGroup
    name: api-service-routes
    matches:
    - metrics
  sources:
  - kind: IdentityBinding
    group: access.smi-spec.io
    name: prometheus
    namespace: default
---
kind: TrafficTarget
metadata:
  name: api-service-api
  namespace: default
spec:
  destination:
    kind: IdentityBinding
    group: access.smi-spec.io
    name: api-service
    namespace: default
  rules:
  - kind: TCPRoute
    name: api-service-port
  - kind: HTTPRouteGroup
    name: api-service-routes
    matches:
    - api
  sources:
  - kind: IdentityBinding
    group: access.smi-spec.io
    name: website-service
    namespace: default
  - kind: IdentityBinding
    group: access.smi-spec.io
    name: payments-service
    namespace: default
```

The previous example would allow the following HTTP traffic:

| source            | destination   | path     | method |
| ----------------- | ------------- | -------- | ------ |
| website-service   | api-service   | /api     | *      |
| payments-service  | api-service   | /api     | *      |
| prometheus        | api-service   | /metrics | GET    |

## Example implementation for L4

The following implementation shows how to define TrafficTargets for
allowing TCP and UDP traffic to specific ports.

```yaml
kind: TCPRoute
metadata:
  name: tcp-ports
spec:
  matches:
    ports:
    - 8301
    - 8302
    - 8300
---
kind: UDPRoute
metadata:
  name: udp-ports
spec:
  matches:
    ports:
    - 8301
    - 8302
---
kind: TrafficTarget
metadata:
  name: protocal-specific
spec:
  destination:
    kind: IdentityBinding
    group: access.smi-spec.io
    name: server
    namespace: default
  rules:
  - kind: TCPRoute
    name: tcp-ports
  - kind: UDPRoute
    name: udp-ports
  sources:
  - kind: IdentityBinding
    group: access.smi-spec.io
    name: client
    namespace: default
```

Note that the above configuration will allow TCP and UDP traffic to
both `8301` and `8302` ports, but will block UDP traffic to `8300`.

## Tradeoffs

- Additive policy - policy that denies instead of only allows is valuable
  sometimes. Unfortunately, it makes it extremely difficult to reason about what
  is allowed or denied in a configuration.

- Resources vs selectors - it would be possible to reference concrete resources
  such as a deployment instead of selecting across pods.

- This access control is on the destination (server) side, implicitly

- Currently the specification does not have provision for the definition of
  higher level elements such as a service. It is probable that this specification
  will change once these elements are defined.

## Out of scope

- Egress policy - TrafficTarget does *not* allow for the possibility of egress
  access control as it selects specific pods and not hostnames. Another object
  will need to be created to manage this use case.

- Ingress policy - assuming clients present the correct identity, this *should*
  work for some kind of ingress. Unfortunately, it does not cover many of the
  common use cases (filtering by hostname) and will need to be expanded to cover
  this use case.

- Other types of policy - having policy around retries, timeouts and rate limits
  would be great. This specific object only manages access control. As policy
  for these examples would be HTTP specific, there needs to be a HTTP specific
  policy object created.
