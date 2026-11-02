#!/bin/bash

# Configuration Variables
KONG_URL="http://localhost:8001"

clear
# Next Dimension ASCII art
echo "Next Dimension Inc"
echo "    _   _   _   _     _   _   _   _   _   _   _   _   _     _   _   _  "
echo "   / \ / \ / \ / \   / \ / \ / \ / \ / \ / \ / \ / \ / \   / \ / \ / \ "
echo "  ( N | e | x | t ) ( D | i | m | e | n | s | i | o | n ) ( I | n | c )"
echo "   \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/   \_/ \_/ \_/ "
echo
echo " Script by Troy Collin"
echo " This script will create new clients and setup API Keys."
echo " v1.1 (Optimized)"
echo ""

# Check if jq is installed before running
if ! command -v jq &> /dev/null; then
    echo "[-] Error: 'jq' is required but not installed. Please install it to run this script."
    exit 1
fi

while :
do
    echo "=========================================="
    echo "Main Menu:"
    echo -e "\t(a) Create New API Customer"
    echo -e "\t(b) List Current Usernames (Placeholder)"
    echo -e "\t(c) Add user to Prod Access Group (Placeholder)"
    echo -e "\t(d) Display API Key (Placeholder)"
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
            # Using -s (silent) and removing -i (headers) so jq can read raw JSON safely
            user_response=$(curl -s -X POST --url "$KONG_URL/consumers/" \
                --data "username=$consumer_name" \
                --data "custom_id=$consumer_id" \
                --data "tags=Prod")

            # Safely extract ID using jq
            consumer_uuid=$(echo "$user_response" | jq -r '.id // empty')

            if [ -z "$consumer_uuid" ]; then
                echo "[-] Error creating consumer. Response from server:"
                echo "$user_response"
                continue
            fi

            echo "[+] Consumer created with UUID: $consumer_uuid"

            # Apply ACL Groups
            echo "[+] Setting up ACL groups..."
            curl -s -X POST "$KONG_URL/consumers/$consumer_uuid/acls" --data "group=Prod-AccessGroup" > /dev/null
            curl -s -X POST "$KONG_URL/consumers/$consumer_uuid/acls" --data "group=UATaccess" > /dev/null
            curl -s -X POST "$KONG_URL/consumers/$consumer_uuid/acls" --data "group=Prod-Access-Positions" > /dev/null

            # Generate API Key
            echo "[+] Generating API Key..."
            key_response=$(curl -s -X POST --url "$KONG_URL/consumers/$consumer_uuid/key-auth/")
            api_key=$(echo "$key_response" | jq -r '.key // empty')

            # Display API key layout safely
            echo ""
            echo " ******************************************"
            echo "   API Key for $consumer_name:"
            echo "   $api_key"
            echo " ******************************************"
            echo ""
            ;;

        "b"|"B")
            echo "[+] Fetching current consumer usernames..."
            curl -s "$KONG_URL/consumers/" | jq -r '.data[].username'
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

