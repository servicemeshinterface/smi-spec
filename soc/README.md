Summer of Code
=====================

Organization Admins
-------------------

If you need help with anything Summer of code related, you can file an issue or
contact one of the admins below:

- Michelle Noorali ([@michellenoorali](https://github.com/michelleN)\):
  [https://twitter.com/michellenoorali](https://twitter.com/michellenoorali)
- Thomas Rampelberg ([@grampelberg](https://github.com/grampelberg)\):
  [https://twitter.com/grampelberg](https://twitter.com/grampelberg)

Communication
-------------

Please reach out to us on the on the [SMI slack](https://aka.ms/smi/slack).

Project Ideas
-------------

Istio Adapter
-------------

- Description: Converting from the SMI APIs to Istio specific configuration is a
  critical part of supporting every service mesh that has been released. There
  has been some work done on this already, but more needs to be done. The work
  involves setting up CI, writing end to end tests, updating the adapter and
  APIs to work with the latest version of Istio and documenting the contribution
  process for the project.
- Recommended Skills: Golang, Kubernetes
- Mentor(s): Michelle Noorali (@michellenoorali)
- Issues:
  [https://github.com/deislabs/smi-adapter-istio/issues/22](https://github.com/deislabs/smi-adapter-istio/issues/22),
  [https://github.com/deislabs/smi-adapter-istio/issues/70](https://github.com/deislabs/smi-adapter-istio/issues/70),
  [https://github.com/deislabs/smi-adapter-istio/issues/81](https://github.com/deislabs/smi-adapter-istio/issues/81)

Consul Connect Metrics
----------------------

- Description: The metrics for SMI are implemented in a [single
  project](https://github.com/deislabs/smi-metrics). Currently, support for
  Linkerd and Istio has been implemented. This project will be to implement
  support for Consul Connect. The work will include implementing the adapter,
  building a helm chart to distribute and writing tests to validate the
  functionality.
- Recommended Skills: Golang
- Mentor(s): Tarun Pothulapati (@tarunpothulapati)
- Issues:
  [https://github.com/deislabs/smi-metrics/issues/39](https://github.com/deislabs/smi-metrics/issues/39)
