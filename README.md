## Service Mesh Interface (code name Smeagol)

The Service Mesh Interface (SMI) is a specification for service meshes that run on
Kubernetes. It defines a common standard that can be implemented by a variety of providers.
This allows for both standardization for end-users and innovation by providers of Service
Mesh Technology. It enables flexibility and interoperability.

### Technical Overview

The SMI is specified as a collection of Kubernetes Custom Resource definitions. These
CRD APIs (details below) can installed onto any Kubernetes cluster and manipulated 
using standard tools. But they don't actually do anything without an SMI provider.

To activate these APIs an SMI provider is run in the Kubernetes cluster. The SMI provider
reflects back on the SMI CRD API, and deploys components into the cluster to implement
the SMI API. This approach to pluggable interfaces is similar to other core
Kubernetes APIs like +NetworkPolicy+ and +Ingress+.

### Goals

The goal of the SMI API is to provide a common, portable set of Service Mesh APIs which
a Kubernetes user can use in a provider agnostic manner. In this way people can define
applications that use Service Mesh technology without tightly binding to any specific
implementation.

### Non-Goals

It is a non-goal for the SMI project to implement a service mesh itself. It merely attempts
to define the common specification. Likewise it is a non-goal to define the extent of what 
it means to be a Service Mesh, but rather a generally useful subset. If SMI providers want
to add provider specific extensions and APIs beyond the SMI spec, they are welcome to do so
We expect that, over time, as more functionality becomes commonly accepted as part of what
it means to be a Service Mesh, those definitions will migrate into the SMI specification.

### Specification

The SMI specification outlines three basic resource types:

* MutualTLS - a resource for managing and configuring encryption between services
* Canary - a resource for defining flexible routing between different versions of a system
* Sidecar - a resource that defines a sidecar (e.g. for basic HTTP monitoring) that can be installed alongside an application.

The details of the APIs can be founded in [specification.md](specification.md)
