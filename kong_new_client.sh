#!/bin/bash

# Configuration Variables
KONG_URL="http://localhost:8001"
LOG_FILE="./kong_manager.log"

clear
# Next Dimension ASCII art
echo "Next Dimension Inc"
echo "    _   _   _   _     _   _   _   _   _   _   _   _   _     _   _   _  "
echo "   / \ / \ / \ / \   / \ / \ / \ / \ / \ / \ / \ / \ / \   / \ / \ / \ "
echo "  ( N | e | x | t ) ( D | i | m | e | n | s | i | o | n ) ( I | n | c )"
echo "   \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/   \_/ \_/ \_/ "
echo
echo " Script by Troy Collin"
echo " This script will manage Kong clients, ACLs, and API Keys."
echo " v1.3 (Fully Featured)"
echo ""

# Helper function to handle logs uniformly
log_action() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# Check if jq is installed before running
if ! command -v jq &> /dev/null; then
    echo "[-] Error: 'jq' is required but not installed. Please install it to run this script."
    exit 1
fi

# Create log file if it doesn't exist
touch "$LOG_FILE"

while :
do
    echo "=========================================="
    echo "Main Menu:"
    echo -e "\t(a) Create New API Customer"
    echo -e "\t(b) List Current Usernames"
    echo -e "\t(c) Add user to Prod Access Group (Assets / Orders)"
    echo -e "\t(d) Display API Key"
    echo -e "\t(e) Consumer & Key Cleanup Options"
    echo -e "\t(z) Exit"
    echo "=========================================="
    echo -n "Please enter your choice: "
    read -r choice

    case $choice in
        "a"|"A")
            read -p "Enter the name of the consumer: " consumer_name
            read -p "Enter the code for this consumer: " consumer_id

            if [ -z "$consumer_name" ] || [ -z "$consumer_id" ]; then
                echo "[-] Error: Consumer name and ID cannot be blank."
                continue
            fi

            echo "[+] Creating consumer..."
            user_response=$(curl -s -X POST --url "$KONG_URL/consumers/" \
                --data "username=$consumer_name" \
                --data "custom_id=$consumer_id" \
                --data "tags=Prod")

            consumer_uuid=$(echo "$user_response" | jq -r '.id // empty')

            if [ -z "$consumer_uuid" ]; then
                echo "[-] Error creating consumer. Response from server:"
                echo "$user_response"
                log_action "ERROR: Failed to create consumer '$consumer_name'"
                continue
            fi

            echo "[+] Consumer created with UUID: $consumer_uuid"
            log_action "CREATED: Consumer '$consumer_name' (UUID: $consumer_uuid, ID: $consumer_id)"

            # Apply ACL Groups
            echo "[+] Setting up ACL groups..."
            curl -s -X POST "$KONG_URL/consumers/$consumer_uuid/acls" --data "group=Prod-AccessGroup" > /dev/null
            curl -s -X POST "$KONG_URL/consumers/$consumer_uuid/acls" --data "group=UATaccess" > /dev/null
            curl -s -X POST "$KONG_URL/consumers/$consumer_uuid/acls" --data "group=Prod-Access-Positions" > /dev/null
            log_action "ACL: Added '$consumer_name' to Prod-AccessGroup, UATaccess, Prod-Access-Positions"

            # Generate API Key
            echo "[+] Generating API Key..."
            key_response=$(curl -s -X POST --url "$KONG_URL/consumers/$consumer_uuid/key-auth/")
            api_key=$(echo "$key_response" | jq -r '.key // empty')

            echo ""
            echo " ******************************************"
            echo "   API Key for $consumer_name:"
            echo "   $api_key"
            echo " ******************************************"
            echo ""
            log_action "KEY: Generated new API Key for '$consumer_name'"
            ;;

        "b"|"B")
            echo "[+] Fetching current consumer usernames..."
            curl -s "$KONG_URL/consumers/" | jq -r '.data[].username'
            echo ""
            ;;

        "c"|"C")
            read -p "Enter the username or UUID of the consumer: " target_user
            if [ -z "$target_user" ]; then
                echo "[-] Error: Username/UUID cannot be blank."
                continue
            fi

            # Check if user exists first
            check_user=$(curl -s "$KONG_URL/consumers/$target_user")
            user_exists=$(echo "$check_user" | jq -r '.id // empty')

            if [ -z "$user_exists" ]; then
                echo "[-] Error: Consumer '$target_user' not found in Kong."
                continue
            fi

            echo "[+] Adding '$target_user' to Prod Access Groups..."
            curl -s -X POST "$KONG_URL/consumers/$target_user/acls" --data "group=Prod-AccessGroup" > /dev/null
            curl -s -X POST "$KONG_URL/consumers/$target_user/acls" --data "group=Prod-Access-Positions" > /dev/null
            echo "[+] Successfully provisioned access."
            echo ""
            log_action "ACL: Manually added '$target_user' to Prod-AccessGroup and Prod-Access-Positions"
            ;;

        "d"|"D")
            read -p "Enter the username or UUID to fetch keys for: " target_user
            if [ -z "$target_user" ]; then
                echo "[-] Error: Username/UUID cannot be blank."
                continue
            fi

            echo "[+] Retrieving API keys..."
            key_lookup=$(curl -s "$KONG_URL/consumers/$target_user/key-auth/")
            keys=$(echo "$key_lookup" | jq -r '.data[].key // empty')

            if [ -z "$keys" ]; then
                echo "[-] No active API keys found for user '$target_user'."
            else
                echo ""
                echo " ******************************************"
                echo "   Active Key(s) for $target_user:"
                echo "$keys" | while read -r single_key; do
                    echo "   -> $single_key"
                done
                echo " ******************************************"
            fi
            echo ""
            ;;

        "e"|"E")
            echo "------------------------------------------"
            echo "Submenu: Cleanup & Deletion"
            echo -e "\t(1) Revoke ALL Keys for a Consumer"
            echo -e "\t(2) Completely Delete a Consumer"
            echo -e "\t(3) Return to Main Menu"
            echo "------------------------------------------"
            echo -n "Select an action: "
            read -r sub_choice

            case $sub_choice in
                1)
                    read -p "Enter the username or UUID to revoke keys: " target_user
                    [ -z "$target_user" ] && continue
                    
                    # Fetch key IDs to delete them individually
                    key_data=$(curl -s "$KONG_URL/consumers/$target_user/key-auth/")
                    key_ids=$(echo "$key_data" | jq -r '.data[].id // empty')
                    
                    if [ -z "$key_ids" ]; then
                        echo "[-] No keys found to revoke."
                    else
                        echo "$key_ids" | while read -r key_id; do
                            curl -s -X DELETE "$KONG_URL/consumers/$target_user/key-auth/$key_id"
                        done
                        echo "[+] All keys revoked successfully."
                        log_action "REVOKE: Revoked all keys for consumer '$target_user'"
                    fi
                    ;;
                2)
                    read -p "Enter the username or UUID to DELETE permanently: " target_user
                    [ -z "$target_user" ] && continue
                    
                    read -p "Are you absolutely sure? (y/N): " confirm
                    if [[ "$confirm" =~ ^[yY]$ ]]; then
                        delete_response=$(curl -s -X DELETE "$KONG_URL/consumers/$target_user")
                        echo "[+] Consumer deleted."
                        log_action "DELETE: Permanently deleted consumer '$target_user'"
                    else
                        echo "[-] Cancelled."
                    fi
                    ;;
                *)
                    continue
                    ;;
            esac
            echo ""
            ;;

        "z"|"Z")
            echo "Exiting. Goodbye!"
            exit 0
            ;;

        *)
            echo "[-] Invalid option, please try again."
            echo ""
            ;;
    esac
done

