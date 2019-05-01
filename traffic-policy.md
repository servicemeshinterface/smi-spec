## Traffic Policy

This resource allows users to define the authorization policy between
applications and clients.

## Specification

### HTTPService

```yaml
kind: HTTPService
apiVersion: v1beta1
metadata:
  name: foo
  namespace: default
resources:
# v1.ObjectReference
- kind: Service
  name: foo
routes:
- name: admin
  methods:
  - GET
  pathRegex: "/admin/.*"
- name: default
  methods: ["*"]
  pathRegex: ".*"
```

### gRPCService

```yaml
kind: gRPCService
apiVersion: v1beta1
metadata:
  name: foo
  namespace: default
resources:
- kind: Service
  name: foo
package: foo.v1
service: SearchService
rpc:
- name: Search
```

### TCPService

```yaml
kind: TCPService
apiVersion: v1beta1
metadata:
  name: foo
  namespace: default
resources:
- kind: Service
  name: foo
```

### TrafficRole

```yaml
kind: TrafficRole
apiVersion: v1beta1
metadata:
  name: path-specific
  namespace: default
resource:
  name: foo
  kind: Deployment
subjects:
- kind: HTTPService
  name: admin
```

### TrafficRoleBinding

```yaml
kind: TrafficRoleBinding
apiVersion: v1beta1
metadata:
  name: account-specific
  namespace: default
subjects:
- kind: ServiceAccount
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

## Use Cases

## Admission Control

TODO ...

## RBAC

TODO ...

## Example Implementation

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
