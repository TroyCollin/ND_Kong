# Next Dimension Inc. — Kong Local Test Environment Setup Guide

This document explains how to stand up a local, containerized **Kong API Gateway** test environment using Docker Compose and configure the necessary runtime plugins (`key-auth` and `acl`) required by your consumer management script.

---

## 1. System Requirements & Prerequisites

Ensure the following tools are installed on your workstation:
*   **Docker Desktop** or **Docker Engine** (v20.10.0 or higher)
*   **Docker Compose** (v2.0.0 or higher)
*   At least **2 GB of free RAM** allocated to Docker

---

## 2. Environment Architecture Overview

The `docker-compose.yml` file provisions a microservice topology inside a dedicated network layout:

*   **Isolated Network (`kong-net`)**: Connects all components using a custom bridge network so services can securely resolve one another using internal container names (`kong-db`, `kong-gateway`).
*   **Persistent Storage Volume (`kong_db_data`)**: Ensures that your configured consumers, plugins, keys, and routes are persistent across container restarts or upgrades.
*   **Healthcheck Interdependency**: The startup order is strictly orchestrated using health constraints (`service_healthy` and `service_completed_successfully`) to avoid race conditions during database bootstrap steps.

---

## 3. Detailed Component Explanations

### 1. PostgreSQL Database (`kong-db`)
*   **Role**: Serves as the relational configuration storage backend for Kong.
*   **Image**: `postgres:15-alpine` (lightweight, minimal attack surface).
*   **Port Forwarding**: Maps host port `5433` to container port `5432` to avoid conflicts if you are already running an instance of PostgreSQL natively on your host machine.
*   **Healthcheck**: Continually tests readiness via `pg_isready` before clearing down-stream services to spin up.

### 2. Migration Bootstrap (`kong-migrations`)
*   **Role**: An ephemeral container that connects to PostgreSQL and runs `kong migrations bootstrap` to initialize database schemas.
*   **Image**: `kong:3.8` (Stable LTS runtime release matching the core gateway version).
*   **Lifecycle**: Auto-terminates with exit code `0` immediately after establishing database table schemas.

### 3. Core Kong Gateway (`kong`)
*   **Role**: Processes traffic proxies, hooks into runtime plugins, and tracks active operational state.
*   **Mapped Infrastructure Ports**:
    *   `8000`: Standard HTTP traffic proxy gateway entry point.
    *   `8001`: Local loopback Admin API endpoint (Targeted directly by your management bash script).
    *   `8002`: The browser-accessible **Kong Manager Graphical User Interface**.

---

## 4. Initialization & Deployment Workflow

### Step 1: Save the Configuration
Save the Docker Compose yaml content into a file named `docker-compose.yml` in your working project environment.

### Step 2: Bring Up the Stack
Execute the standard deployment command to run the containers in detached (background) mode:
```bash
docker compose up -d
```

### Step 3: Monitor Setup Progress
Because the setup orchestrates standard database migrations, you can monitor the sequential container initialization phases using the command below:
```bash
docker compose logs -f
```
*Look for `kong-migrations` to exit successfully, followed by `kong-gateway` starting its listener processes on ports `8000`, `8001`, and `8002`.*

---

## 5. Global Plugin Activation

Before your consumer script can restrict traffic or validate keys, you must activate the corresponding security plugins on the Kong cluster. Run these commands from your host machine terminal once the containers are running.

### 1. Enable Key Authentication (`key-auth`)
This plugin intercepts incoming proxy requests and ensures they pass a valid credential string via your chosen headers or query parameters (defaults to checking for a `apikey` header parameter).

To enable it globally across all routes:
```bash
curl -X POST http://localhost:8001/plugins \
  --data "name=key-auth" \
  --data "config.key_names=apikey"
```

### 2. Enable Access Control Lists (`acl`)
The ACL plugin works alongside `key-auth`. Once a consumer's identity is verified by their API Key, this plugin checks if their assigned group string matches your allowed routing rules.

To enable it globally across all routes:
```bash
curl -X POST http://localhost:8001/plugins \
  --data "name=acl" \
  --data "config.allow=Prod-AccessGroup" \
  --data "config.hide_groups_header=true"
```
*Note: Using `config.allow` ensures that only clients belonging to the specified group (which your script attaches during option A or C) can successfully proxy past the gateway layer.*

---

## 6. Verifying the Test Environment

Once everything is up, you can verify your runtime boundaries locally before running your administration shell script:

1.  **Kong Manager Web UI**: Open your preferred browser and navigate to [http://localhost:8002](http://localhost:8002) to view the graphical cluster dashboard and confirm both plugins are active under the "Plugins" menu.
2.  **Admin API Loopback**: Query the status endpoint to verify communication capability:
    ```bash
    curl -i http://localhost:8001/status
    ```
    *A successful environment will return an HTTP status of `200 OK` along with data regarding database connectivity status.*

---

## 7. Tearing Down the Infrastructure

To stop the containers without destroying database configurations:
```bash
docker compose down
```

To wipe the workspace completely—including all created consumers, keys, and API gateway routes—include the volume flag:
```bash
docker compose down -v
```

