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

Please reach out to us on the [SMI slack](https://aka.ms/smi/slack) in
the #general channel.

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
- Mentor(s): Tarun Pothulapati (@tarunpothulapati), Nic Jackson
  (@sheriffjackson)
- Issues:
  [https://github.com/deislabs/smi-metrics/issues/39](https://github.com/deislabs/smi-metrics/issues/39)

HPA Support
-----------

- Description: It is valuable to scale workloads on metrics other than
  cpu/memory. To do this today, you must use the custom metrics API and the
  prometheus adapter. With the SMI metrics API it should be possible to get HPA
  working with that API. This project should integrate HPA and SMI metrics to
  allow for scaling on rps as well as latency. The work includes demonstrating
  how to do this, documenting it, adding as an end to end test and producing a
  demo tha shows off to end users how it all works.
- Recommended Skills: Golang, Kubernetes
- Mentor(s): Thomas Rampelberg (@grampelberg)
- Issues:
  [https://github.com/deislabs/smi-spec/issues/96](https://github.com/deislabs/smi-spec/issues/96)

Conformance Tool
-----------

- Description:  Ensure that a service mesh is properly configured and that its behavior
  conforms to official SMI specifications. Conformance consists of both capabilities
  and compliance status as outlined in the design specification. Use Meshery as the
  underlying technology to support SMI validation.
- Recommended Skills: Golang, Kubernetes
- Mentor(s): Lee Calcote (@lcalcote), Sagar Utekar (@named_uttu)
- Issues: [https://github.com/servicemeshinterface/smi-spec/issues/70](https://github.com/servicemeshinterface/smi-spec/issues/70)
- Design Spec: [https://docs.google.com/document/d/1HL8Sk7NSLLj-9PRqoHYVIGyU6fZxUQFotrxbmfFtjwc/edit#](https://docs.google.com/document/d/1HL8Sk7NSLLj-9PRqoHYVIGyU6fZxUQFotrxbmfFtjwc/edit#)