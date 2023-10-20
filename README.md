<!-- markdownlint-disable MD041 -->
![SMI Logo](./images/smi-banner.png)

# :warning: This project is [ARCHIVED](https://www.cncf.io/archived-projects/). [Learn more](https://www.cncf.io/blog/2023/10/03/cncf-archives-the-service-mesh-interface-smi-project/)

## Service Mesh Interface

The Service Mesh Interface (SMI) is a specification for service meshes, with a
focus on those that run on Kubernetes. It defines a common standard that can be
implemented by a variety of providers. This allows for both standardization for
end-users and innovation by providers of Service Mesh Technology. SMI enables
flexibility and interoperability, and covers the most common service mesh
capabilities.

### Service Mesh Interface Documents

The following documents are available:

|                               |         Latest Release             |  
| :---------------------------- | :--------------------------------: |
| **Core Specification:**       |
| SMI Specification             |  [v0.6.0](/SPEC_LATEST_STABLE.md) |
|                               |
| **Specification Components**  |
| Traffic Access Control  |  [v1alpha3](/apis/traffic-access/v1alpha3/traffic-access.md)  |
| Traffic Metrics   |  [v1alpha1](/apis/traffic-metrics/v1alpha1/traffic-metrics.md)  |
| Traffic Specs  |  [v1alpha4](/apis/traffic-specs/v1alpha4/traffic-specs.md)  |
| Traffic Split  |  [v1alpha4](/apis/traffic-split/v1alpha4/traffic-split.md) |

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
* **Argo Rollouts:** advanced deployment & progressive delivery controller ([argoproj.io](https://argoproj.github.io/argo-rollouts))

\* via adaptor

## Communications

### Community Meeting

* SMI community meetings are on hiatus until October 12, 2022 to allow for
focus on the [GAMMA initiative](https://smi-spec.io/blog/announcing-smi-gateway-api-gamma/).
  * [Meeting notes](https://docs.google.com/document/d/1NTBaJf6LhUBlF8_lfvBBt_MbyPvT-6CZNg6Ckpm_yCo/edit?usp=sharing)
  * [CNCF YouTube Playlist for SMI community meetings](https://www.youtube.com/playlist?list=PLL6_4qADP2SpZ_dWUY0okz5zOgrs_HAqg)

### Slack

* [CNCF Slack](https://cloud-native.slack.com):
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
