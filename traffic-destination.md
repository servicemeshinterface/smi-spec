# Traffic Destination
Allows the configuration of Istio Virtual Service and Consul Service Resolvers using SMI

## Destination Rule - Istio

Notes:
  https://istio.io/docs/reference/config/networking/v1alpha3/destination-rule/

```

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-destination
spec:
  host: reviews.prod.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
      consistentHash:
         httpCookie:
           name: user
           path: /something
           ttl: 0s
         httpHeaderName: X-SESSION-ID
         useSourceIp: true
         minimumRingSize: 1024
    connectionPool:
      tcp:
        connectTimeout:
        maxConnections: 100
        tcpKeepalive:
          time: 7200ms
          interval: 80s
      http:
        http1MaxPendingRequests: 1024
        http2MaxRequests: 1024
        maxRequestsPerConnection: 100
        maxRetries: 1024
        idleTimeout: 10s
      outlierDetection:
        consecutiveErrors: 7
        interval: 5m
        baseEjectionTime: 15m
        maxEjectionPercent: 10%
        minHealthPercent: 50%
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      #...
  - name: v2
    labels:
      version: v2
```

# Consul - Service Resolver
```
kind           = "service-resolver"
name           = "web"
default_subset = "v1"
subsets = {
  "v1" = {
    filter = "Service.Meta.version == v1"
  }
  "v2" = {
    filter = "Service.Meta.version == v2"
  }
}

kind = "service-resolver"
name = "web-dc2"
redirect {
  service    = "web"
  datacenter = "dc2"
}

kind            = "service-resolver"
name            = "web"
connect_timeout = "15s"
failover = {
  "*" = {
    datacenters = ["dc3", "dc4"]
  }
}
```