## Traffic Access Control

This set of resources allows users to define access control policy for their
applications. It is the *authorization* side of the picture. Authentication
should already be handled by the underlying implementation and surfaced through
a subject.

Access control in this specification is *additive*, all traffic is denied by
default. See [tradeoffs](#tradeoffs) for a longer discussion about why.

## Specification

### TrafficTarget

A `TrafficTarget` associates a set of traffic definitions (rules) with a service identity which is allocated to a group of pods.
, access is controlled via referenced TrafficSpecs and by a list of source service identities.
If a pod which holds the referenced service identity makes a call to the destination on one of the defined routes then access
will be allowed. 
Any pod which attempts to connect and is not in the defined list of sources will be denied.
Any pod which is in the defined list but attempts to connect on a route which is not in the list of Twill be denied.

Access is controlled based on service identity, at present the method of assigning service identity is using Kubernetes Service accounts,
provision for other identity mechanisms will be handled by the spec at a later date.

Specs are [traffic specs](traffic-specs.md) that define what traffic for
specific protocols would look like. The kind can be different depending on what
traffic a target is serving. In the following examples, `HTTPRouteGroup` is used for
applications serving HTTP based traffic.

To understand how this all fits together, first define the routes for some
traffic.

```yaml
apiVersion: v1beta1
kind: HTTPRouteGroup
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
---
kind: TrafficTarget
apiVersion: access.smi-spec.io/v1alpha1
metadata:
 name: path-specific
 namespace: default
destination:
 kind: ServiceAccount
 name: service-a
 namespace: default
 port: 8080
specs:
- kind: HTTPRouteGroup
  name: the-routes
  matches:
    - metrics
sources:
- kind: ServiceAccount
  name: prometheus
  namespace: default
```

This example selects all the pods which have the `service-a` `ServiceAccount`. Traffic
destined on a path `/metrics` is allowed. The `matches` field
is optional and if omitted, a rule is valid for all the matches in a traffic
spec (a OR relationship).
It is possible for a service to expose multiple ports, the `port` field allows the 
user to specify specifically which port traffic should be allowed on. `port` is an optional
element, if not specified, traffic will be allowed to all ports on the destination service.

Allowing destination traffic should only be possible with permission of the 
service owner. Therefore, RBAC rules should be configured to control the pods
which are allowed to assign the `ServiceAccount` defined in the TrafficTarget destination.

**Note:** access control is *always* enforced on the *server* side of a connection
(or the target). It is up to implementations to decide whether they would also
like to enforce access control on the *client* (or source) side of the
connection as well.

Source identities which are allowed to connect to the destination is defined in the sources list.
Only pods which have a `ServiceAccount` which is named in the sources list are allowed to connect
to the destination.

## Example Implementation

The following implementation shows four services api, website, payment and prometheus, it shows how it is possible
to write fine grained TrafficTargets which allow access to be controlled by route and source.

```yaml
apiVersion: specs.smi-spec.io/v1alpha1
kind: HTTPRouteGroup
metadata:
  name: api-service-routes
matches:
  - name: api
    pathRegex: /api
    methods: ["*"]
  - name: metrics
    pathRegex: /metrics
    methods: ["GET"]

---
kind: TrafficTarget
apiVersion: access.smi-spec.io/v1alpha1
metadata:
 name: api-service-metrics
 namespace: default
destination:
 kind: ServiceAccount
 name: api-service
 namespace: default
 port: 8080
specs:
- kind: HTTPRouteGroup
  name: api-service-routes
  matches:
    - metrics
sources:
- kind: ServiceAccount
  name: prometheus
  namespace: default

---
kind: TrafficTarget
apiVersion: access.smi-spec.io/v1alpha1
metadata:
 name: api-service-api
 namespace: default
destination:
 kind: ServiceAccount
 name: api-service
 namespace: default
 port: 8080
specs:
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
| ------ ---------- | ------------- | -------- | ------ |
| website-service   | api-service   | /api     | *      |
| payments-service  | api-service   | /api     | *      |
| prometheus        | api-service   | /metrics | GET    |

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
