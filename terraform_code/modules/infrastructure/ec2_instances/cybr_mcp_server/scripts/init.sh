#!/usr/bin/env bash
set -eux

# ========================================================================
# PART 1: SET HOSTNAME
# ========================================================================
set_hostname() {
    local NEW_HOST="$1"
    local FLAG=/var/log/set_hostname_done
    local LOG=/var/log/set-hostname-first-boot.log
    
    if [[ -f "$FLAG" ]]; then
        echo "[init] Hostname already set; skipping." | tee -a "$LOG"
        return 0
    fi
    
    {
        date && echo "[init] Setting hostname → $NEW_HOST"
        hostnamectl set-hostname "$NEW_HOST"
        
        # update /etc/hosts
        if grep -q '^127\.0\.1\.1' /etc/hosts; then
            sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $NEW_HOST/" /etc/hosts
        else
            echo "127.0.1.1 $NEW_HOST" >> /etc/hosts
        fi
        
        echo "[init] Hostname and /etc/hosts updated."
        echo "[init] Hostname setup complete."
    } 2>&1 | tee -a "$LOG"s
    
    touch "$FLAG"
}

# ========================================================================
# PART 2: CONFIGURE SIA ENDPOINT  
# ========================================================================
configure_sia_endpoint() {
    local LOG=/var/log/sia_configure.log
    local FLAG=/var/log/sia_configure_done
    
    # Check for required tools
    for cmd in aws jq curl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "[register] ERROR: '$cmd' not installed" >&2
            exit 1
        fi
    done
    
    # Validate required environment variables
    : "${AWS_REGION:?AWS_REGION is required}"
    : "${PLATFORM_SECRET_ARN:?PLATFORM_SECRET_ARN is required}"
    : "${IDENTITY_TENANT_ID:?IDENTITY_TENANT_ID is required}"
    : "${PLATFORM_TENANT_NAME:?PLATFORM_TENANT_NAME is required}"
    : "${WORKSPACE_ID:?WORKSPACE_ID is required}"
    : "${WORKSPACE_TYPE:?WORKSPACE_TYPE is required}"
    : "${USERNAME_DOMAIN:?USERNAME_DOMAIN is required}"
    
    # Idempotency guard
    if [[ -f "$FLAG" ]]; then
        echo "[register] SIA registration already completed; skipping." | tee -a "$LOG"
        return 0
    fi
    
    {
        echo "[$(date)] [register] Starting target configuration"
        
        # 1) Fetch CyberArk platform credentials
        echo "[$(date)] [register] Fetching platform creds from Secrets Manager"
        secret_json=$(aws secretsmanager get-secret-value \
            --region "$AWS_REGION" \
            --secret-id "$PLATFORM_SECRET_ARN" \
            --query SecretString --output text)
        
        client_id=$(jq -r '.username' <<<"$secret_json")@${USERNAME_DOMAIN}
        client_secret=$(jq -r '.password' <<<"$secret_json")
        
        # 2) Obtain OAuth token 
        IDENTITY_URL="https://${IDENTITY_TENANT_ID}.id.cyberark.cloud"
        PLATFORM_TOKEN_URL="${IDENTITY_URL}/oauth2/platformtoken"
        
        echo "[$(date)] [register] Requesting OAuth token (multipart/form-data)"
        resp=$(curl -sk -w "\n%{http_code}" \
            -X POST "$PLATFORM_TOKEN_URL" \
            -H "Accept: application/json" \
            -F "grant_type=client_credentials" \
            -F "client_id=${client_id}" \
            -F "client_secret=${client_secret}")
        
        http_code=$(tail -n1 <<<"$resp")
        body=$(sed '$d' <<<"$resp")
        
        echo "[$(date)] [register] HTTP status: $http_code"
        echo "[$(date)] [register] Response body: $body"
        
        platform_token=$(jq -r '.access_token // empty' <<<"$body")
        echo "[$(date)] [register] Parsed access_token: $platform_token"
        
        if [[ -z "$platform_token" ]]; then
            echo "[$(date)] [register] ERROR: Failed to obtain platform token" >&2
            exit 1
        fi
        
        # 3) Get Configure Script & Configure the target system
        CONFIGURE_TARGET_API_URL="https://${PLATFORM_TENANT_NAME}.dpa.cyberark.cloud/api/public-keys/scripts"
        echo "[$(date)] [register] Requesting setup script from ${CONFIGURE_TARGET_API_URL}"
        setup_resp=$(curl -sk -X GET "$CONFIGURE_TARGET_API_URL" \
            -H "Authorization: Bearer ${platform_token}" \
            -H "Content-Type: application/json" \
            -d "workspaceId=${WORKSPACE_ID}" \
            -d "workspaceType=${WORKSPACE_TYPE}"
        )
        
        # Decode the Base64 payload into bash_cmd
        base64_payload=$(jq -r '.base64_cmd' <<<"$setup_resp")
        if [[ -z "$base64_payload" || "$base64_payload" == "null" ]]; then
            echo "[$(date)] [register] ERROR: No 'base64_cmd' returned in setup response" >&2
            exit 3
        fi
        
        bash_cmd=$(echo "$base64_payload" | base64 --decode)
        echo "[$(date)] [register] Executing decoded setup script"
        eval "$bash_cmd"
        
        # 5) Invalidate token
        echo "[$(date)] [register] Logging out"
        curl -sk -X POST "${IDENTITY_URL}/security/logout" \
             -H "Authorization: Bearer ${platform_token}" || true
        
        echo "[$(date)] [register] Connector registration completed successfully"
    } 2>&1 | tee -a "$LOG"
    
    # Mark done
    touch "$FLAG"
}

# ========================================================================
# PART 3: INSTALL DOCKER
# ========================================================================
install_docker() {
    local LOG=/var/log/docker_install.log
    local FLAG=/var/log/docker_install_done
    
    if [[ -f "$FLAG" ]]; then
        echo "[docker] Docker already installed; skipping." | tee -a "$LOG"
        return 0
    fi
    
    {
        echo "[$(date)] [docker] Starting Docker installation"
        
        # 1) Update OS
        yum update -y
        
        # 2) Install Docker
        yum install -y docker
        
        # 3) Start and enable Docker service
        systemctl start docker
        systemctl enable docker
        
        # 4) Add ec2-user to docker group
        usermod -a -G docker ec2-user
        
        # 5) Install Docker Compose
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        
        # 6) Create a symbolic link for docker-compose
        ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        
        echo "[$(date)] [docker] Docker installation completed successfully"
    } 2>&1 | tee -a "$LOG"
    
    touch "$FLAG"
}

# ========================================================================
# MAIN EXECUTION
# ========================================================================
main() {
    echo "[$(date)] Starting SCA MCP Server initialization"
    
    # Get hostname from first argument
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 HOSTNAME" >&2
        exit 1
    fi
    
    local hostname="$1"
    
    # Execute in order: hostname, SIA config, Docker
    echo "[$(date)] Step 1: Setting hostname"
    set_hostname "$hostname"
    
    echo "[$(date)] Step 2: Configuring SIA endpoint"
    configure_sia_endpoint
    
    echo "[$(date)] Step 3: Installing Docker"
    install_docker
    
    echo "[$(date)] SCA MCP Server initialization completed successfully"
}

# Run main function with all arguments
main "$@"