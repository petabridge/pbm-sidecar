# Petabridge.Cmd Docker Sidecar

[Petabridge.Cmd](https://cmd.petabridge.com/) sidecar Docker image - designed to be run side-by-side with [Akka.NET](https://getakka.net/) applications that expose the [Petabridge.Cmd.Host port](https://cmd.petabridge.com/articles/install/host-configuration.html).

## Usage: Commandline

To use `petabridge/pbm` on the CLI:

```shell
docker run -d --name sidecar-pbm petabridge/pbm:latest
```

And shell into it via `docker exec`:

```shell
docker exec -it sidecar-pbm /bin/bash
```

## Usage: `docker-compose`

You can use the `petabridge/pbm` image alongside Akka.NET applications inside a `docker-compose.yml` file:

```yml
version: '3.8'

services:
  shardhost-app:
    image: docker.testlab.net/duplicate-shards-expr:latest
    container_name: shardhost-app
    restart: unless-stopped
    environment:
      - AkkaSettings__ActorSystemName=DupeShards
      - AkkaSettings__RemoteOptions__Port=8081
      - ASPNETCORE_ENVIRONMENT=Development
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4317
      - OTEL_RESOURCE_ATTRIBUTES=service.namespace=expr-dupe-shards-control,service.instance.id=shardhost-app
      - OTEL_SERVICE_NAME=shardhost
    ports:
      - "8558:8558"
      - "8081:8081"
      - "9110:9110"

  pbm-sidecar:
    image: petabridge/pbm:latest
    container_name: pbm-sidecar
    restart: unless-stopped
    depends_on:
      - shardhost-app

```

## Usage: Kubernetes

You can also use `petabridge/pbm` inside Akka.NET applications deployed in Kubernetes:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: shardhost
  namespace: expr-dupe-shards-control
  labels:
    app: shardhost
    cluster: dupeshard
spec:
  serviceName: shardhost
  replicas: 3
  selector:
    matchLabels:
      app: shardhost
  template:
    metadata:
      labels:
        app: shardhost
        cluster: dupeshard
    spec:
      serviceAccountName: shardhost
      terminationGracePeriodSeconds: 35
      containers:
      - name: shardhost-app
        image: docker.testlab.net/duplicate-shards-expr:latest # custom app image
        imagePullPolicy: Always
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: NODE_IP
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
        - name: AkkaSettings__ActorSystemName
          value: "DupeShards"
        - name: AkkaSettings__RemoteOptions__Port
          value: "8081"
        - name: AkkaSettings__RemoteOptions__PublicHostname
          value: "$(POD_NAME).shardhost.$(NAMESPACE)"
        - name: ASPNETCORE_ENVIRONMENT
          value: "Development"
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "http://$(NODE_IP):4317"
        - name: OTEL_RESOURCE_ATTRIBUTES
          value: "service.namespace=$(NAMESPACE),service.instance.id=$(POD_NAME)"
        - name: OTEL_SERVICE_NAME
          value: "shardhost"
        - name: AkkaSettings__PhobosSettings__TracingMode
          value: "UserOnly"
        - name: AkkaSettings__PhobosSettings__MetricsMode
          value: "All"
        - name: AkkaSettings__ClusterBootstrapOptions__RequiredContactPointsNr
          value: "3"
        - name: AkkaSettings__ClusterBootstrapOptions__KubernetesDiscoveryOptions__PodNamespace
          value: "$(NAMESPACE)"
        - name: AkkaSettings__ClusterBootstrapOptions__KubernetesDiscoveryOptions__PodLabelSelector
          value: "cluster={0}"
        readinessProbe:
          tcpSocket: 
            port: 8558  
        ports:
          - containerPort: 8558
            protocol: TCP
            name: management
          - containerPort: 8081
            protocol: TCP
            name: akka-remote
          - containerPort: 9110
            protocol: TCP
            name: pbm
      - name: pbm-sidecar
        image: petabridge/pbm:latest #sidecar
```

Copyright 2015-2025 [Petabridge](https://petabridge.com/), LLC.