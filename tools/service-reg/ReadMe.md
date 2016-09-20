## Service Registry

This is a very light weighted service registry service. The intention was less to provide a rock solid and secure solution, this is more for sand-boxing.

Kubernetes exposes services via environment variables. This registry can run within a Pod by allowing to store service details. The API is fairly simple:

```
    POST /config/:id/:value
    GET /config/:id
    GET /config
```

The environment variable SERVICE_REG_STORAGE can be set to a folder (to which write permission is existent) in order to persist the configuration.
