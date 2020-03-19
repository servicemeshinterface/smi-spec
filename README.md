<!-- markdownlint-disable MD041 -->
![SMI Logo](./images/smi-banner.png)

## Service Mesh Interface

The Service Mesh Interface (SMI) is a specification for service meshes that run
on Kubernetes. It defines a common standard that can be implemented by a variety
of providers. This allows for both standardization for end-users and innovation
by providers of Service Mesh Technology. It enables flexibility and
interoperability.

This specification consists of multiple APIs:

* [Traffic Access Control](traffic-access-control.md) - configure access to specific
  pods and routes based on the identity of a client for locking down
  applications to only allowed users and services.
* [Traffic Specs](traffic-specs.md) - define how traffic looks on a per-protocol
  basis. These resources work in concert with access control and other types of
  policy to manage traffic at a protocol level.
* [Traffic Split](traffic-split.md) - incrementally direct percentages of
  traffic between various services to assist in building out canary rollouts.
* [Traffic Metrics](traffic-metrics.md) - expose common traffic metrics for use
  by tools such as dashboards and autoscalers.

See the individual documents for the details. Each document outlines:

* Specification
* Possible use cases
* Example implementations
* Tradeoffs

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
APIs beyond the SMI spec, they are welcome to do so. We expect that, over time,
as more functionality becomes commonly accepted as part of what it means to be a
Service Mesh, those definitions will migrate into the SMI specification.

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

## Ecosystem

* **Consul Connect\*:** service segmentation ([consul.io/docs/connect](https://consul.io/docs/connect))
* **Flagger:** progressive delivery operator ([flagger.app](https://flagger.app))
* **Istio\*:** connect, secure, control, observe ([deislabs/smi-adapter-istio](https://github.com/deislabs/smi-adapter-istio))
* **Linkerd:** ultralight service mesh ([linkerd.io](https://linkerd.io))
* **Maesh:** simpler service mesh ([mae.sh](https://mae.sh))
* **Rio:** application deployment engine ([rio.io](https://rio.io))
* **Service Mesh Hub:** unified dashboard ([solo.io/products/service-mesh-hub](https://solo.io/products/service-mesh-hub))
* **SuperGloo:** mesh orchestration ([supergloo.solo.io](https://supergloo.solo.io))

\* via adaptor

## Communications

### Community Meeting

* Community Meeting: every other Wednesday at 9:30-10:30 Pacific: [https://zoom.us/j/448032371](https://zoom.us/j/448032371)
  * [Calendar invite](https://calendar.google.com/calendar/embed?src=v2ailcfbvg9mgco5p0ms4t8ou8%40group.calendar.google.com&ctz=America%2FLos_Angeles)
  * [Meeting notes](https://docs.google.com/document/d/1NTBaJf6LhUBlF8_lfvBBt_MbyPvT-6CZNg6Ckpm_yCo/edit?usp=sharing)

### Slack

* [SMI Slack](https://smi-spec.slack.com):
  * [#general](https://smi-spec.slack.com/messages/general)

[Sign up](https://aka.ms/smi/slack) for SMI Slack

## Contributing

Please refer to [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on
contributing to the specification.

## Support

Whether you are a user or contributor, you can open issues on GitHub:

* [Issues](https://github.com/deislabs/smi-spec/issues)

## License

The specification is licensed under [OWF Contributor License Agreement 1.0 -
Copyright and
Patent](http://www.openwebfoundation.org/legal/the-owf-1-0-agreements/owf-contributor-license-agreement-1-0---copyright-and-patent)
in the [LICENSE](./LICENSE) file.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of
conduct](https://opensource.microsoft.com/codeofconduct/). For more information
see the [Code of Conduct
FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact
opencode@microsoft.com (mailto:opencode@microsoft.com) with any additional
questions or comments.
