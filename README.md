# Next Dimension Inc. — Kong Consumer Manager Documentation

This document provides a comprehensive guide for the **Kong Consumer Management Bash Script** (`v1.3`). The script automates administrative tasks on a Kong API Gateway instance, including creating consumers, binding access control lists (ACLs), managing key authentication, tracking actions via local logs, and performing system cleanup.

---

## 1. System Requirements & Architecture

The script operates locally or from a management server that has direct access to the **Kong Admin API**.

### Prerequisites
*   **Operating System**: Linux (Ubuntu, CentOS, Debian, etc.) or macOS with a `bash` shell context.
*   **Kong API Gateway**: A working Kong instance with the Admin API exposed (defaulting to `http://localhost:8001`).
*   **Kong Plugins**: The script relies on the following plugins being globally enabled or enabled on the respective routes/services:
    *   `key-auth` (Key Authentication)
    *   `acl` (Access Control Lists)
*   **System Utilities**:
    *   `curl`: Used to perform HTTP operations (`POST`, `GET`, `DELETE`) against the Admin API endpoints.
    *   `jq`: A flexible, command-line JSON processor used to securely extract target variables from Kong's native JSON responses.

To install `jq` on your system:
```bash
# Ubuntu / Debian
sudo apt update && sudo apt install jq -y

# CentOS / RHEL
sudo dnf install epel-release -y && sudo dnf install jq -y

# macOS
brew install jq
```

---

## 2. Global Variables & Initialization

At the beginning of the script, configuration boundaries are explicitly declared for ease of maintenance:

*   `KONG_URL="http://localhost:8001"`: Points to the administrative boundary of your Kong cluster. If the port changes or moves to a remote server, update this value.
*   `LOG_FILE="./kong_manager.log"`: Defines the operational logging vector.

### Environment Pre-flight Check
Before launching the main interface loop, the script verifies system dependencies and prepares the runtime environment:
```bash
if ! command -v jq &> /dev/null; then
    echo "[-] Error: 'jq' is required but not installed..."
    exit 1
fi
touch "$LOG_FILE"
```

---

## 3. Detailed Operational Workflows

### Option A: Create New API Customer
This workflow structures a clean onboarding path for a client by executing four back-to-back operations:
1.  **Consumer Provisioning**: Sends a request to `/consumers/` with a unique `username`, a unique `custom_id` (used for internal mapping), and applies a `Prod` metadata tag.
2.  **JSON Validation**: The raw API payload is parsed via `jq -r '.id // empty'`. If an ID is missing (e.g., due to a duplicate entry error or network timeout), the script logs the failure context and exits gracefully back to the main menu.
3.  **ACL Association**: It issues sequential requests to binding pathways (`/consumers/{id}/acls`) to map the user into security zones: `Prod-AccessGroup`, `UATaccess`, and `Prod-Access-Positions`.
4.  **Credential Generation**: Issues a `POST` request to the consumer's `/key-auth/` sub-resource to instantiate an API key string, displaying it securely inside a visual CLI banner.

### Option B: List Current Usernames
Provides a clean view of the current landscape by making a basic `GET` request to `/consumers/`. It abstracts away the systemic payload metadata and isolates just the raw usernames using an array filter:
```bash
curl -s "$KONG_URL/consumers/" | jq -r '.data[].username'
```

### Option C: Manual ACL Provisioning
Designed to handle legacy or altered consumer states. When passed an arbitrary username or UUID, it explicitly tests existence against `/consumers/{target}`. If valid, it enforces baseline structural configurations onto the client by rebinding `Prod-AccessGroup` and `Prod-Access-Positions` ACL strings.

### Option D: API Key Retrieval
Retrieves current secrets safely. Kong permits multiple API keys per consumer context for token rotation scenarios. Option D loops through the `.data[].key` JSON array structure and lists *every* active credential mapped to that client footprint.

### Option E: Cleanup & Deletion Submenu
Houses destructive configurations behind a distinct logical loop to prevent system errors:
*   **Key Revocation**: Targets the `/key-auth/` registry of a user, collects the distinct unique identifiers (`id`) assigned to each issued credential string, and loops through them via `DELETE` invocations.
*   **Permanent Purge**: Drops the entire consumer profile using a `DELETE` request to the base `/consumers/{target}` layout. This operation forces an interactive `y/N` input safeguard to verify intention.

---

## 4. Logging & Audit Trails

To support compliance tracking, the custom internal bash function `log_action()` handles append operations seamlessly:

```bash
log_action() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}
```

### Log Signature Examples
The resulting `kong_manager.log` output documents the exact state transitions for system auditing:
```text
2026-11-02 10:15:32 - CREATED: Consumer 'AlphaClient' (UUID: a1b2c3d4-e5f6..., ID: CUST-101)
2026-11-02 10:15:33 - ACL: Added 'AlphaClient' to Prod-AccessGroup, UATaccess, Prod-Access-Positions
2026-11-02 10:15:34 - KEY: Generated new API Key for 'AlphaClient'
2026-11-02 10:22:11 - ACL: Manually added 'BetaClient' to Prod-AccessGroup and Prod-Access-Positions
2026-11-02 10:45:01 - REVOKE: Revoked all keys for consumer 'TestUser'
2026-11-02 10:45:15 - DELETE: Permanently deleted consumer 'TestUser'
```

---

## 5. Execution Instructions

1.  Save the code block locally as `manage_kong.sh`.
2.  Elevate permissions to make the file an executable binary resource:
    ```bash
    chmod +x manage_kong.sh
    ```
3.  Execute the framework environment directly from your terminal:
    ```bash
    ./manage_kong.sh
    ```
