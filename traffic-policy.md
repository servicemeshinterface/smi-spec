## Traffic Policy

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

## Specification

### TrafficRole

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

### TrafficRoleBinding

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

### ClusterTrafficRole

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

### ClusterTrafficRoleBinding

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

## Workflow

## Use Cases {#policy-use-cases}

### OpenAPI/Swagger

Many REST applications provide OpenAPI definitions for their endpoints,
operations and authentication methods. Consuming these definitions and
generating policy automatically allows developers and organizations keep the
definition of their policy in a single location. A given specification can be
used to create `TrafficRole` and `TrafficRoleBinding` objects as part of a CI/CD
workflow.

TODO - specification mapping

## Tradeoffs {#policy-tradeoffs}

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

## Out of scope

* Egress policy - while this specification allows for the possibility of
  defining egress configuration, this functionality is currently out of scope.
* Non-HTTP traffic - this specification will need to be expanded to support
  traffic such as Kafka or MySQL.

## Open Questions

* Why include namespace in the reference *and* role? Is there any reason a user
  would create a role in one namespace that references another?
* Namespaces should *not* be possible to define on `TrafficRole` for resource
  references but are required for `ClusterTrafficRole`. Is it okay only allow
  this key in `ClusterTrafficRole` references?
* I'm not sure `kind: pod` and `name: *` is the best solution for generic allow
  policies. Is there a better way to do it? `kind: *` feels wrong as well.

