
---

# NixOS Server Configuration (nix-ax41)

This repository contains the full declarative configuration for the `nix-ax41` NixOS host. It is structured as a modular, flake-based system providing a complete monitoring, logging and reverse-proxy stack with secure TLS automation and secret management.

---

## Overview

The system implements:

* TLS certificates provisioned via ACME (Let’s Encrypt)
* Nginx reverse proxy with multiple virtual hosts
* Prometheus metrics collection
* Loki log aggregation
* Promtail system journal scraping
* Grafana dashboards with provisioned datasources
* Zabbix server, web frontend and agent
* Secure secret management via `sops-nix`
* Declarative service layout with isolated Nix modules
* mariadb/MySQL backend for Zabbix
* Subdomain routing for all exposed services
* Functional flake deployment for consistent builds

DNS is **not** hosted on the machine itself. Zones are managed at the domain registrar/provider side.

---

## Repository Layout

```
/etc/nixos
├── configuration.nix
├── flake.nix
├── flake.lock
├── hardware-configuration.nix
├── modules/
│   ├── dns.nix
│   ├── fail2ban.nix
│   ├── networking.nix
│   ├── nginx.nix
│   ├── observability.nix
│   ├── secrets.nix
│   ├── wazuh.nix
│   └── zabbix.nix
└── secrets/
    └── zabbix.yaml
```

### Highlights

* `configuration.nix`: Base OS config, RAID, SSH, firewall, bootloader, user accounts.
* `flake.nix`: Entry point defining the NixOS system and included modules.
* `modules/`: All custom service modules logically separated.
* `secrets/`: Encrypted YAML secrets handled by `sops-nix`.

---

## Major Components

### 1. TLS / ACME

Handled via:

```nix
security.acme.acceptTerms = true;
```

Certificates are automatically issued for:

* `grafana.devopsincoming.com`
* `prometheus.devopsincoming.com`
* `zabbix.devopsincoming.com`
* `loki.devopsincoming.com`

Nginx virtual hosts use `enableACME = true` and enforce HTTPS.

---

### 2. Nginx Reverse Proxy

Nginx is configured as a frontend for:

| Service            | Upstream         | Virtual Host                    |
| ------------------ | ---------------- | ------------------------------- |
| Grafana            | `127.0.0.1:3000` | `grafana.devopsincoming.com`    |
| Prometheus         | `127.0.0.1:9090` | `prometheus.devopsincoming.com` |
| Zabbix Web         | PHP-FPM socket   | `zabbix.devopsincoming.com`     |
| Loki UI (optional) | n/a              | not exposed in config (Bad UI)  |

Includes recommended TLS, proxy, gzip and security settings.

Zabbix is served via PHP-FPM using:

```
fastcgi_pass unix:/run/phpfpm/zabbix.sock
```

---

### 3. Prometheus

Prometheus runs on port `9090` and scrapes:

* Local node exporter (`localhost:9100`)

Configuration uses a 15-second scrape interval and runs as a standard service.

---

### 4. Loki

Loki is enabled with:

* BoltDB Shipper storage
* Filesystem chunk storage under `/srv/loki`
* In-memory ring
* HTTP: 3100
* gRPC: 19095

The node autodetects interfaces from `networking.interfaces`.

---

### 5. Promtail

Promtail collects systemd journal logs and ships them to:

```
http://localhost:3100/loki/api/v1/push
```

Includes relabeling to attach `unit=<systemd unit>` labels.

---

### 6. Grafana

Grafana runs locally on port `3000` with:

* Provisioned Prometheus datasource
* Provisioned Loki datasource
* Correct external domain configuration for reverse proxy use

---

### 7. Zabbix

The full Zabbix stack is configured:

* Zabbix Server
* Zabbix Agent
* Zabbix Web (PHP-FPM frontend)
* MariaDB backend

Database credentials are supplied by `sops-nix`:

```
sops.secrets."zabbix_db_password"
```

Nginx serves the Zabbix PHP frontend.

---

## Secret Management (sops-nix)

Encrypted YAML secrets located under `secrets/` are decrypted at runtime using:

```
sops.age.keyFile = "/var/lib/sops-nix/key.txt";
```

`.sops.yaml` ensures all `secrets/*.yaml` files are encrypted using the host’s age key.

---

## Networking & Security

### Firewall

Open ports:

* 22 (SSH)
* 80 (HTTP)
* 443 (HTTPS)
* 53 (DNS, though DNS service is disabled)

### SSH

* Root login disallowed by password
* PasswordAuth disabled globally
* Only SSH key authentication

### Fail2Ban

Enabled with an enforced custom jail for SSH brute-force protection.

---

## Boot & Storage

### RAID

Software RAID is enabled with mdadm-managed arrays:

* `/dev/md126` (swap)
* `/dev/md127` (boot)

### Filesystems

Mounted partitions for `/`, `/boot`, and `/srv`.

---

## Deployment

The system is fully flake-based:

```
nixosConfigurations.nix-ax41 = lib.nixosSystem { ... };
```

Typical rebuild:

```
sudo nixos-rebuild switch --flake /etc/nixos#nix-ax41
```

---

## Summary

The server is configured as learning NixOS and DevSecOps utility infrastructure. It implements a complete observability and monitoring platform with secure HTTPS, encrypted secrets, reverse proxying, metrics, logs, dashboards and alerting infrastructure, entirely managed declaratively. The modular setup allows easy extension, reproducible builds, and consistent infrastructure.

More tools will be added in the next few days/weeks e.g. Security Hardening with Falco and OpenSCAP, CI/CD Build Pipeline with ArgoCD and/or Github Actions, SIEM and Endpoint tools and so on...


