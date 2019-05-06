## Traffic Access Control

This resource allows users to define policies that control access to resources
for clients.

## Specification

### TrafficRole

```yaml
kind: TrafficRole
apiVersion: access.smi-spec.io/v1alpha1
metadata:
  name: path-specific
  namespace: default
resource:
  name: foo
  kind: Deployment
port: 8080
rules:
- kind: HTTPRoutes
  name: the-routes
  specs:
  - metrics
```

This example associates a set of routes with a set of pods. It will match the
routes arriving at these pods on the specified port (8080). While `the-routes`
definition contains multiple elements, only a single element is referenced in
this role. This example could be used in conjunction with a TrafficRoleBinding
to provide Prometheus the access to scrape metrics on the `foo` deployment.

### TrafficRoleBinding

```yaml
kind: TrafficRoleBinding
apiVersion: access.smi-spec.io/v1alpha1
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

This example grants the ability to access the routes in `path-specific` to any
client providing the identity `bar` based on a ServiceAccount.

As access control is additive, it is important to provide definitions that allow
non-authenticated traffic access. Imagine rolling a service mesh out
incrementally. It is important to not immediately block any traffic that is not
from an authenticated client. In this world, groups are important as a source of
identity.

```yaml
kind: TrafficRoleBinding
apiVersion: access.smi-spec.io/v1alpha1
metadata:
  name: account-specific
  namespace: default
subjects:
- kind: Group
  name: system:unauthenticated
roleRef:
  kind: TrafficRole
  name: path-specific
```

This example allows any unauthenticated client access to the rules defined in
`path-specific`.

Note: this specification defines that access control is *always* enforced on the
*server* side of a connection. It is up to implementations to decide whether
they would also like to enforce access control on the *client* side
of the connection as well.

## Use Cases

## Admission Control

TODO ...

## RBAC

TODO ...

## Example Implementation

## Tradeoffs

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
