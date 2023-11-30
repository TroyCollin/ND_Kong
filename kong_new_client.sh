#!/bin/bash

clear
# Next Dimension ASCII art.
echo "Next Dimension Inc"

echo "    _   _   _   _     _   _   _   _   _   _   _   _   _     _   _   _  "
echo "   / \ / \ / \ / \   / \ / \ / \ / \ / \ / \ / \ / \ / \   / \ / \ / \ "
echo "  ( N | e | x | t ) ( D | i | m | e | n | s | i | o | n ) ( I | n | c )"
echo "   \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/   \_/ \_/ \_/ "
echo
echo " script by Troy Collin"
echo
echo " This script will create new clients and setup API Key"
echo " Script will ask for info like client name that will be used"
echo ""
echo "v.1.0"

read -p "Enter the name of the consumer: " consumer_name
read -p "Enter the code for this consumer: " consumer_id


curl -i -X POST --url http://localhost:8001/consumers/ --data 'username=$consumer_name'--data 'custom_id=$consumer_id' --data 'tags=Prod'
curl -X POST 'http://127.0.0.1:8001/consumers/a7c21bee-be2d-41f7-8988-921f8af91f71/acls' --data "group=Prod-AccessGroup"
curl -X POST 'http://127.0.0.1:8001/consumers/a7c21bee-be2d-41f7-8988-921f8af91f71/acls' --data "group=UATaccess"
curl -X POST 'http://127.0.0.1:8001/consumers/a7c21bee-be2d-41f7-8988-921f8af91f71/acls' --data "group=Prod-Access-Positions"
curl -i -X POST --url 'http://localhost:8001/consumers/a7c21bee-be2d-41f7-8988-921f8af91f71/key-auth/'

