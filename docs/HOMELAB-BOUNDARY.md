---
title: Homelab Boundary
tags: [docker, homelab, security, architecture]
---

# Homelab Boundary

Daily-driver and VM rebuilds must remain independent from server deployment.

## This repository may do

- install Docker Engine
- install Docker Compose
- enable the local Docker service after explicit `containers` selection
- add the current user to the Docker group
- run basic diagnostics

## This repository must not do

- clone or deploy Compose services
- expose ports
- configure a reverse proxy
- restore Docker volumes
- create production secrets
- start Immich, n8n, Actual Budget, Open WebUI, or other services
- assume the current computer is a server

## Future homelab repository

```text
homelab/
├── services/
├── compose/
├── networks/
├── proxy/
├── monitoring/
├── backup/
└── docs/
```

The future homelab repo may depend on `linux-setup` having installed Docker. `linux-setup` should never depend on the homelab repo.
