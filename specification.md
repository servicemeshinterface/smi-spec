## SMI Specification

### Overview

The SMI specification consists of three APIs:

* Mutual TLS - Used for implementing encryption between Pods
* Canary - Used for traffic shapping between versions of a service
* Sidecar - Used for injecting sidecars (eg Monitoring) onto applications.

### Mutual TLS 

This resource is used to inject a sidecar that performs Mutual TLS. 
This results in every Pod that matches the selector driving their traffic through TLS
with the subject names specified in the spec. 

```yaml
apiVersion: v1beta1 
kind: TLSConfig 
name: my-tls-config 
spec: 
   # Subject names in the Certificate
   subjectNames:
   - foo 
   - bar
   # Selector to identify Pods that have this TLS
   selector:
     matchLabels:
       role: frontend
       stage: production
``` 

### Canary 

This resource is used to create a percentage-based load-splitting between various services. This will create an HTTP resource that splits traffic between multiple services.
This resource will itself be a Kubernetes Service, in this case with the name `my-canary`. 

```yaml
apiVersion: v1beta1 
kind: Canary
name: my-canary 
spec: 
   services: 
    - service-1: 50% 
    - service-2: 20% 
    - service-3: 10%
```

### Sidecar
The Sidecar resource defines a sidecar container which is injected alongside the application. The primary use case is to perform HTTP monitoring. A monitoring sidecar collects standard HTTP metrics (status codes, requests / second, latency, etc) and exposes a common interface using Prometheus metrics.
These metrics can be picked up by a metrics scraper and pushed to either an in-cluster or
in-cloud monitoring endpoint.

```yaml
apiVersion: v1beta1
kind: Sidecar
name: my-monitor
spec:
  # The monitor sidecar is added to Pods matching these labels
  selector:
    matchLabels:
      role: frontend
      stage: production
  # These labels are applied to the prometheus metrics streams.
  metricLabels:
    team: my-team
    app: my-server
    region: us-east
```
