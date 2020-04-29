# Service Mesh Interface

## Version

This is SMI **spec** version **v0.3.0-WD**.
WD stands for `working draft`.
Learn more about versioning [below](#versioning).

## Table of Contents

- [Abstract](#abstract)
- [Objective](#objective)
- [Technical Overview](#technical-overview)
- [APIs](#apis)
  - [Access Control](#traffic-access)
  - [Split](#traffic-split)
  - [Specs](#traffic-specs)
  - [Metrics](#traffic-metrics)
  - [API Development Process](#api-development-process)
- [Appendix](#appendix)
  - [Terminology](#terminology)
  - [Versioning](#versioning)
  - [Notational Conventions](#notational-conventions)

## Abstract

The Service Mesh Interface (SMI) is a specification for service meshes that run
on Kubernetes. It defines a common standard that can be implemented by a variety
of providers. This allows for both standardization for end-users and innovation
by providers of Service Mesh Technology. SMI enables flexibility and
interoperability, and covers the most common service mesh capabilities.

## Objective

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

## Technical Overview

The SMI is specified as a collection of Kubernetes APIs via Kubernetes Custom
Resource Definitions (CRD) and Extension API Servers. These APIs can be
installed onto any Kubernetes cluster and manipulated using standard tools.
The APIs require an SMI provider to do something.

To activate these APIs an SMI provider is run in the Kubernetes cluster. For the
resources that enable configuration, the SMI provider reflects back on their
contents and configures the provider's components within a cluster to implement
the desired behavior. In the case of extension APIs, the SMI provider translates
from internal types to those the API expects to return.

This approach to pluggable interfaces is similar to other core Kubernetes APIs
like +NetworkPolicy+, +Ingress+ and +CustomMetrics+.

## APIs

Find each API described at a high level below. Follow the links to see the
individual API specification documents for the details. Each document outlines:

- Specification
- Possible use cases
- Example implementations
- Tradeoffs

### Traffic Access Control

Apply policies like identity and transport encryption across services.

The [Traffic Access Control](apis/traffic-access/traffic-access.md) API
describes a resource to configure access to specific pods and routes based
on the identity of a client for locking down applications to only allowed
users and services.

### Traffic Split

Shift traffic between different services.

The [Traffic Split](apis/traffic-split/traffic-split.md) API describes
a resource to incrementally direct percentages of traffic between various services
to assist in building out canary rollouts.

### Traffic Specs

Describe traffic on a per-protocol basis.

The [Traffic Specs](apis/traffic-specs/traffic-specs.md) API describes
a set of resources to define how traffic looks on a per-protocol basis. These
resources work in concert with access control and other types of policy to manage
traffic at a protocol level.

### Traffic telemetry

Capture key metrics like error rate and latency between services

The [Traffic Metrics](apis/traffic-metrics/traffic-metrics.md) API
exposes common traffic metrics for use by tools such as dashboards and autoscalers.

### API Development Process

Please submit an issue or a pull request to this repository to propose a change.
Changes are discussed on the [SMI community meetings](README.md/$communications).
Changes should be made to documents of each API which can be found in the corresponding
directories under [apis/](apis/).

## Appendix

### Terminology

- **SMI Provider**: An implementor of SMI. This could be a service mesh.
- **API Group**: A set of resources that are exposed together. Each group may have
one or more versions that evolve independently of other API Groups. Group names are
in domain form.

### Versioning

The spec has its own version listed [above](#version). This version describes the
specification in its entirety. Although it is not related to the API specification
versions, the minor version of the spec will be incremented every time any of the
API Specification versions are incremented.
