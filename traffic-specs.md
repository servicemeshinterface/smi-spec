## Traffic Spec

This set of resources allows users to specify how their traffic looks. It is
used in concert with access control and other policies to concretely define what
should happen to specific types of traffic as it flows through the mesh.

There are many different protocols that users would like to have be part of a
mesh. Right now, this is primarily HTTP, but it is possible to imagine a world
where service meshes are aware of other protocols. Each resource in this
specification is meant to match 1:1 with a specific protocol. This allows users
to define the traffic in a protocol specific fashion.

## Specification

### HTTPRouteGroup

This resource is used to describe HTTP/1 and HTTP/2 traffic. It enumerates the
routes that can be served by an application.

```yaml
apiVersion: specs.smi-spec.io/v1alpha1
kind: HTTPRouteGroup
metadata:
  name: the-routes
matches:
- name: metrics
  pathRegex: "/metrics"
  methods:
  - GET
- name: health
  pathRegex: "/ping"
  methods: ["*"]
filters:
- kind: Service
  name: foobar
  ports:
  - 8080
```

This example defines two matches, `metrics` and `health`. The name is the
primary key and all fields are required. A regex is used to match against the
URI and is anchored (`^`) to the beginning of the URI. Methods can either be
specific (`GET`) or `*` to match all methods.

These routes have not yet been associated with any resources. See
[access control](traffic-access-control.md) for an example of how routes become
associated with applications serving traffic.

The `matches` field only applies to URIs. It is common to look at other parts of
an HTTP request. This is where `filters` come in:

```yaml
apiVersion: v1beta1
kind: HTTPRouteGroup
metadata:
  name: the-routes
  namespace: default
matches:
- name: everything
  pathRegex: ".*"
  methods: ["*"]
filters:
- kind: Service
  name: foobar
  ports:
  - 8080
```

This example defines a single route that matches anything. It then describes a
filter. This filter looks at the `Host` or `:authority` header and scopes the
route matches to requests with the value
`foobar.default.svc.cluster.local:8080`. This is the FQDN of the `foobar`
service and port listed.

At initial glance, filters and matches are pretty similar. There are some
important differences. In particular, *all* filters must match whereas `matches`
simply define what the traffic *could* look like. Individual matches are used
regularly with TrafficTargets (see the `/metrics` example above).

### TCPRoute

This resource is used to describe L4 TCP traffic. It is a simple route which configures
an application to receive raw non protocol specific traffic.

```
apiVersion: specs.smi-spec.io/v1alpha1
kind: TCPRoute
metadata:
  name: tcp-route
```

## Automatic Generation

While it is possible for users to create these by hand, the recommended pattern
is for tools to do it for the users. OpenAPI specifications can be consumed to
generate the list of routes. gRPC protobufs can similarly be used to
automatically generate the list of routes from code.

## Tradeoffs

* These specifications are *not* directly associated with applications and other
  resources. They're used to describe the type of traffic flowing through a mesh
  and used by higher level policies such as access control or rate limiting. The
  policies themselves bind these routes to the applications serving traffic.

## Out of scope

* gRPC - there should be a gRPC specific traffic spec. As part of the first
  version, this has been left out as HTTPRouteGroup can be used in the interim.

* Arbitrary header filtering - there should be a way to filter based on headers.
  This has been left out for now, but the specification should be expanded to
  address this use case.
