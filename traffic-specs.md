# Traffic Spec `v1alpha2`

This set of resources allows users to specify how their traffic looks. It is
used in concert with [access control](traffic-access-control.md) and other
policies to concretely define what should happen to specific types of traffic
as it flows through the mesh.

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
apiVersion: specs.smi-spec.io/v1alpha2
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
```

This example defines two matches, `metrics` and `health`. The name is the
primary key and all fields are required. A regex is used to match against the
URI and is anchored (`^`) to the beginning of the URI. Methods can either be
specific (`GET`) or `*` to match all methods.

These routes have not yet been associated with any resources. See
[access control](traffic-access-control.md) for an example of how routes become
associated with applications serving traffic.

The `matches` field only applies to URIs and HTTP headers.

```yaml
apiVersion: specs.smi-spec.io/v1alpha2
kind: HTTPRouteGroup
metadata:
  name: the-routes
  namespace: default
matches:
- name: everything
  pathRegex: ".*"
  methods: ["*"]
```

This example defines a single route that matches anything.

### HTTP header filters

A route definition can specify a list of HTTP header filters.
A filter defines a match condition that's applied to incoming HTTP requests.
The filters defined in a route group can be associated with a
[traffic split](traffic-split.md) thus enabling traffic shifting
for A/B testing scenarios.

A HTTP filter is a key-value pair, the key is the name of the HTTP header and
the value is a regex expression that defines the match condition for that header.

A route with multiple header filters represents an `AND` condition while multiple
routes each with its own header filter represents an `OR` condition.

```yaml
apiVersion: specs.smi-spec.io/v1alpha2
kind: HTTPRouteGroup
metadata:
  name: the-routes
  namespace: default
matches:
- name: android-insiders
  headers:
  - user-agent: ".*Android.*"
  - cookie: "^(.*?;)?(type=insider)(;.*)?$"
```

The above example defines a filter that targets Android users with a
`type=insider` cookie.

```yaml
apiVersion: specs.smi-spec.io/v1alpha2
kind: HTTPRouteGroup
metadata:
  name: the-routes
  namespace: default
matches:
- name: android-insiders
  headers:
  - user-agent: ".*Android.*"
  - cookie: "^(.*?;)?(type=insider)(;.*)?$"
- name: firefox-users
  headers:
  - user-agent: ".*Firefox.*"
```

The above example defines two routes that target Android users with a `type=insider`
cookie or Firefox users.

A route that targets a specific path and/or HTTP methods can contain header filters:

```yaml
apiVersion: specs.smi-spec.io/v1alpha2
kind: HTTPRouteGroup
metadata:
  name: the-routes
matches:
- name: iphone-users
  pathRegex: "/api/.*"
  methods:
  - GET
  - HEAD
  headers:
  - user-agent: ".*iPhone.*"
```

The above example defines a route that targets iPhone users that are issuing
`GET` or `HEAD` requests to `/api`.

When `pathRegex` and `methods` are not defined, the header filters are applied
to any path and all HTTP methods.

### TCPRoute

This resource is used to describe L4 TCP traffic. It is a simple route which configures
an application to receive raw non protocol specific traffic.

```yaml
apiVersion: specs.smi-spec.io/v1alpha1
kind: TCPRoute
metadata:
  name: tcp-route
```

### UDPRoute

This resource is used to describe L4 UDP traffic. It is a simple route which configures
an application to receive raw non protocol specific traffic.

```yaml
apiVersion: specs.smi-spec.io/v1alpha4
kind: UDPRoute
metadata:
  name: udp-route
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
