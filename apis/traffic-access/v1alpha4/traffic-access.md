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

### TrafficAccess

A `TrafficAccess` associates a set of traffic definitions (rules) with a
service identity which is allocated to a group of pods.  Access is controlled
via referenced [TrafficSpecs](/apis/traffic-specs/v1alpha4/traffic-specs.md)
and by a list of source service identities.  If a pod which holds the reference
service identity makes a call to the destination on one of the defined routes
then access will be allowed. Any pod which attempts to connect and is not in
the defined list of sources will be denied.  Any pod which is in the defined
list but attempts to connect on a route which is not in the list of
`TrafficSpecs` will be denied.

Access is controlled based on service identity, at present the method of
assigning service identity is using Kubernetes service accounts, provision for
other identity mechanisms will be handled by the spec at a later date.

Rules are [traffic specs](/apis/traffic-specs/v1alpha4/traffic-specs.md) that
define what traffic for specific protocols would look like. The kind can be
different depending on what traffic a target is serving. In the following
examples, `HTTPRouteGroup` is used for applications serving HTTP based traffic.

A valid `TrafficAccess` must specify a destination, at least one rule, and
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
Prometheus. To define the target for this traffic, it takes a `TrafficAccess`.

```yaml
---
kind: TrafficAccess
metadata:
  name: path-specific
  namespace: default
spec:
  destination:
    kind: ServiceAccount
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
  - kind: ServiceAccount
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
which are allowed to assign the `ServiceAccount` defined in the TrafficAccess
destination.

**Note:** access control is *always* enforced on the *server* side of a
connection (or the target). It is up to implementations to decide whether they
would also like to enforce access control on the *client* (or source) side of
the connection as well.

Source identities which are allowed to connect to the destination is defined in
the sources list.  Only pods which have a `ServiceAccount` which is named in
the sources list are allowed to connect to the destination.

## Example implementation for L7

The following implementation shows four services api, website, payment and
prometheus. It shows how it is possible to write fine grained TrafficAccesss
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
kind: TrafficAccess
metadata:
  name: api-service-metrics
  namespace: default
spec:
  destination:
    kind: ServiceAccount
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
  - kind: ServiceAccount
    name: prometheus
    namespace: default
---
kind: TrafficAccess
metadata:
  name: api-service-api
  namespace: default
spec:
  destination:
    kind: ServiceAccount
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
  - kind: ServiceAccount
    name: website-service
    namespace: default
  - kind: ServiceAccount
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

The following implementation shows how to define TrafficAccesss for
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
kind: TrafficAccess
metadata:
  name: protocal-specific
spec:
  destination:
    kind: ServiceAccount
    name: server
    namespace: default
  rules:
  - kind: TCPRoute
    name: tcp-ports
  - kind: UDPRoute
    name: udp-ports
  sources:
  - kind: ServiceAccount
    name: client
    namespace: default
```

Note that the above configuration will allow TCP and UDP traffic to
both `8301` and `8302` ports, but will block UDP traffic to `8300`.

## Tradeoffs

* Additive policy - policy that denies instead of only allows is valuable
  sometimes. Unfortunately, it makes it extremely difficult to reason about what
  is allowed or denied in a configuration.

* Resources vs selectors - it would be possible to reference concrete resources
  such as a deployment instead of selecting across pods.

* As this access control is on the destination (server) side, implicitly

* Currently the specification does not have provision for the definition of
  higher level elements such as a service. It is probable that this specification
  will change once these elements are defined.

## Out of scope

* Egress policy - TrafficAccess does *not* allow for the possibility of egress
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
