## Service Mesh Interface

The Service Mesh Interface (SMI) is a specification for service meshes that run
on Kubernetes. It defines a common standard that can be implemented by a variety
of providers. This allows for both standardization for end-users and innovation
by providers of Service Mesh Technology. It enables flexibility and
interoperability.

This specification consists of multiple APIs:

* [Traffic Specs](traffic-specs.md) - define how traffic looks on a per-protocol
  basis. These resources work in concert with access control and other types of
  policy to manage traffic at a protocol level.
* [Traffic Access Control](traffic-access-control.md) - configure access to specific
  pods and routes based on the identity of a client for locking down
  applications to only allowed users and services.
* [Traffic Split](traffic-split.md) - incrementally direct percentages of
  traffic between various services to assist in building out canary rollouts.
* [Traffic Metrics](traffic-metrics.md) - expose common traffic metrics for use
  by tools such as dashboards and autoscalers.

See the individual documents for the details. Each document outlines:

* Specification
* Possible use cases
* Example implementations
* Tradeoffs

### Technical Overview

The SMI is specified as a collection of Kubernetes Custom Resource Definitions
(CRD) and Extension API Servers. These APIs can be installed onto any Kubernetes
cluster and manipulated using standard tools. The APIs require an SMI provider
to do something.

To activate these APIs an SMI provider is run in the Kubernetes cluster. For the
resources that enable configuration, the SMI provider reflects back on their
contents and configures the provider's components within a cluster to implement
the desired behavior. In the case of extension APIs, the SMI provider translates
from internal types to those the API expects to return.

This approach to pluggable interfaces is similar to other core Kubernetes APIs
like +NetworkPolicy+, +Ingress+ and +CustomMetrics+.

### Goals

The goal of the SMI API is to provide a common, portable set of Service Mesh
APIs which a Kubernetes user can use in a provider agnostic manner. In this way
people can define applications that use Service Mesh technology without tightly
binding to any specific implementation.

### Non-Goals

It is a non-goal for the SMI project to implement a service mesh itself. It
merely attempts to define the common specification. Likewise it is a non-goal to
define the extent of what it means to be a Service Mesh, but rather a generally
useful subset. If SMI providers want to add provider specific extensions and
APIs beyond the SMI spec, they are welcome to do so We expect that, over time,
as more functionality becomes commonly accepted as part of what it means to be a
Service Mesh, those definitions will migrate into the SMI specification.

## Communications

### Slack Channel
#general Slack channel for related discussion in the
[SMI Slack](http://smi-spec.slack.com).

If you are not yet a member of the SMI Slack you may sign up [here](https://aka.ms/smi/slack).

### Contributing

Please refer to [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on contributing to the specification.

### License
The specification is licensed under [OWF Contributor License Agreement 1.0 - Copyright and Patent](http://www.openwebfoundation.org/legal/the-owf-1-0-agreements/owf-contributor-license-agreement-1-0---copyright-and-patent) in the [LICENSE](./LICENSE) file.
