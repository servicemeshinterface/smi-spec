# Service Mesh Hub by Solo.io

The Service Mesh Hub is an example integration of the SMI Specification.
Service Mesh Hub is a mesh agnostic dashboard to install and operate meshes. A
read only version of the Service Mesh Hub can be found on
[servicemeshhub.io](https://servicemeshhub.io)

Service Mesh Hub does:

* Built-in installers for different meshes
* Automatically discovers existing meshes, their configurations, running
 services / extensions and registers them to the Hub to manage
* Install and manage meshes and mesh extensions
* Extensions Tab has ecosystem tools for service mesh environments. Users can
 also build their own extensions
* Demos Tab has demo apps for trying out mesh use cases

## Instructions to install Service Mesh Hub

Install Service Mesh Hub on any Kubernetes cluster with the command:

```
bash kubectl apply -f
https://raw.githubusercontent.com/solo-io/service-mesh-hub/master/install/service-mesh-hub.yaml
```

This will install the hub into the `sm-marketplace` namespace. Once the pods are
running, you can open the hub by port forwarding:

```
bash kubectl port-forward -n sm-marketplace deploy/smm-apiserver 8080
```

Then navigate your browser to `localhost:8080`

Go to Extensions Tab, select SMI and install that extension onto an existing
mesh or install a mesh to add SMI.

## More Info

* [Community Slack](https://slack.solo.io)
  * #Service-Mesh-Hub Slack channel for related discussion
* [Website](https://www.solo.io)
* [Demo Video](https://www.youtube.com/watch?v=4ePBXG1UuCI&t=122s)
