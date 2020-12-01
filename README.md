<!-- markdownlint-disable MD041 -->
![SMI Logo](./images/smi-banner.png)

![CI](https://github.com/servicemeshinterface/smi-spec/workflows/CI/badge.svg)

## Service Mesh Interface

The Service Mesh Interface (SMI) is a specification for service meshes that run
on Kubernetes. It defines a common standard that can be implemented by a variety
of providers. This allows for both standardization for end-users and innovation
by providers of Service Mesh Technology. SMI enables flexibility and
interoperability, and covers the most common service mesh capabilities.

### Service Mesh Interface Documents

The following documents are available:

|                               |         Latest Release             |    Working Draft                           |
| :---------------------------- | :--------------------------------: | :----------------------------------------: |
| **Core Specification:**       |
| SMI Specification             |  [v0.5.0](/SPEC_LATEST_STABLE.md) |  [v0.6.0-WD](/SPEC_WORKING_DRAFT.md)  |
|                               |
| **Specification Components**  |
| Traffic Access Control  |  [v1alpha2](/apis/traffic-access/v1alpha2/traffic-access.md)  |  [v1alpha3-WD](/apis/traffic-access/traffic-access-WD.md)          |
| Traffic Metrics   |  [v1alpha1](/apis/traffic-metrics/v1alpha1/traffic-metrics.md)  |  [v1alpha2-WD](/apis/traffic-metrics/traffic-metrics-WD.md)          |
| Traffic Specs  |  [v1alpha3](/apis/traffic-specs/v1alpha3/traffic-specs.md)  |  [v1alpha4-WD](/apis/traffic-specs/traffic-specs-WD.md)          |
| Traffic Split  |  [v1alpha3](/apis/traffic-split/v1alpha3/traffic-split.md) |  [v1alpha4-WD](/apis/traffic-split/traffic-split-WD.md)          |

## Ecosystem

* **Consul Connect\*:** service segmentation ([consul.io/docs/connect](https://consul.io/docs/connect))
* **Flagger:** progressive delivery operator ([flagger.app](https://flagger.app))
* **Gloo Mesh:** Multi-cluster service mesh management plane
 ([solo.io/products/gloo-mesh](https://solo.io/products/gloo-mesh))
* **Istio\*:** connect, secure, control, observe ([servicemeshinterface/smi-adapter-istio](https://github.com/servicemeshinterface/smi-adapter-istio))
* **Linkerd:** ultralight service mesh ([linkerd.io](https://linkerd.io))
* **Traefik Mesh:** simpler service mesh ([traefik.io/traefik-mesh](https://traefik.io/traefik-mesh))
* **Meshery:** the service mesh management plane ([layer5.io/meshery](https://layer5.io/meshery))
* **Rio:** application deployment engine ([rio.io](https://rio.io))
* **Open Service Mesh:** lightweight and extensible cloud native service mesh ([openservicemesh.io](https://openservicemesh.io))

\* via adaptor

## Communications

### Community Meeting

* Community Meeting: every other Wednesday at 10:00-10:30 Pacific: [https://zoom.us/my/cncfsmiproject](https://zoom.us/my/cncfsmiproject)
  * [Calendar invite](https://calendar.google.com/calendar/embed?src=v2ailcfbvg9mgco5p0ms4t8ou8%40group.calendar.google.com&ctz=America%2FLos_Angeles)
  * [Meeting notes](https://docs.google.com/document/d/1NTBaJf6LhUBlF8_lfvBBt_MbyPvT-6CZNg6Ckpm_yCo/edit?usp=sharing)
  * [CNCF YouTube Playlist for SMI community meetings](https://www.youtube.com/playlist?list=PLj6h78yzYM2N5upvsCMVbct4WSrKJo49p)

### Slack

* [SMI Slack](https://cloud-native.slack.com):
  * [#smi](https://cloud-native.slack.com/messages/smi)

[Sign up](https://slack.cncf.io/) for CNCF Slack

## Contributing

Please refer to [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on
contributing to the specification.

## Support

Whether you are a user or contributor, you can open issues on GitHub:

* [Issues](https://github.com/servicemeshinterface/smi-spec/issues)

## Community Code of Conduct

Service Mesh Interface follows the [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/master/code-of-conduct.md).
