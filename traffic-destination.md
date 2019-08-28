# Traffic Destination
Allows the configuration of routable Virtual Services 

## Destination Rule - Istio

## Specification

```

apiVersion: destination.smi-spec.io/v1alpha1
kind: TrafficDestination
metadata:
  name: foo-destination
spec:
  host: foo.prod.svc.cluster.local
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
  - name: v2
    labels:
      version: v2
  redirect:
    service: web
    datacenter: dc1
    subset: v1
    namespace: default
  failover:
    service: web
    subset: v1
    namespace: default
    datacenters:
      - dc2
      - dc3
```

### Host
Name of the service from the service registry to which the TrafficDestination applies.

### TrafficPolicy - Optional
This section allows the configuration of load balancing and connection pool settings. Should the TrafficPolicy section be omitted from the specification then default settings will be applied.

### LoadBalancer - Optional
Load balancer allows the configuration of load balancing settings for the TrafficDestination. Load balancers can have two types, simple which routes traffic on a round robin or random basis, and consistentHash which allows routing of traffic based on user defined criteria such as HTTP cookie or HTTP header. Only one option can be specified at any time.

#### Simple
Simple load balancing has 4 different options for the type of LoadBalancer to be used.

```yaml
loadBalancer:
  simple: ROUND_ROBIN
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

* ROUND_ROBIN - Requests are distributed to hosts on a round robin basis
* LEAST_CONN - Requests are distributed to the host which currently has the lowest number of connections (There is implementation specific behaviour here)
* RANDOM - Requests are distributed to a randomly selected host

#### ConsistentHash
ConsistentHash load balancing allows sophisticated routing based on data provided in the request. Examples of use for ConsistentHash include:
connect_timeout = "15s"
failover = {

* Sticky sessions - a request should always be sent to the same host
* Load balancing cache servers - Horizontal scale of cache servers like Elasticache or Redis, is generally performed by sharding data across each of the instances. In order to ensure that the data is 
stored and retrieved from the correct shard a hash is computed based on the object or request parameters.

```yaml
loadBalancer:
  consistentHash:
     httpCookie:
       name: user
       path: /something
       ttl: 0s
     httpHeaderName: X-SESSION-ID
     useSourceIp: true
     minimumRingSize: 1024
```

|                 |        |          |                                    |
| --------------- | ------ | -------- | ---------------------------------- |
| httpCookie      | string | oneof    | use HTTP cookie                    |
| httpHeaderName  | string | oneof    | hash based on HTTP header          |
| useSourceIp     | bool   | oneof    | use source ip of downstream client |
| minimumRingSize | int    | optional | time to live                       |

##### HTTPCookie
HTTPCookie allows configuration of the 


|      |          |          |                    |
| ---- | -------- | -------- | ------------------ |
| name | string   | required | name of the cookie |
| path | string   | required | path of the cookie |
| ttl  | duration | optional | time to live       |
