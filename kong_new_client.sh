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


while :
do
echo "Main Menu:"
echo -e "\t(a) Create New API Customer"
echo -e "\t(b) List Current Usernames"
echo -e "\t(c) Add user to Prod Access Group ( Assets / Orders)"
echo -e "\t(d) Display API Key"

echo -e "\t(z) Exit"
echo -n "Please enter your choice:"
read choice
case $choice in
"a"|"A")
read -p "Enter the name of the consumer: " consumer_name
read -p "Enter the code for this consumer: " consumer_id


user=$(curl -i -X POST --url http://localhost:8001/consumers/ --data "username=$consumer_name" --data "custom_id=$consumer_id" --data "tags=Prod")
echo "$user"
consumer_data=$(echo "$user" | grep id | cut -d'"' -f 14)
echo "$consumer_data"
curl -X POST "http://127.0.0.1:8001/consumers/$consumer_data/acls" --data "group=Prod-AccessGroup"
curl -X POST "http://127.0.0.1:8001/consumers/$consumer_data/acls" --data "group=UATaccess"
curl -X POST "http://127.0.0.1:8001/consumers/$consumer_data" --data "group=Prod-Access-Positions"
curl -X POST --url "http://localhost:8001/consumers/$consumer_data/key-auth/"


# display API key
key=$(curl -X GET --url "http://localhost:8001/consumers/$consumer_data/key-auth/")
key1=$(echo "$key" | cut -d'"' -f 10)

echo ""
echo "Here is the API Key"
echo ""
echo " ******************************************"
echo " *                                        * "
echo "   $key1"
echo " *                                        *"
echo " ******************************************"
echo ""
bash ./kong_new_client.sh
;;
"b"|"B")

curl -X POST "http://127.0.0.1:8001/consumers/" | jq | grep "username"
read -n 1 -s -r -p "Press any key to continue"
bash ./kong_new_client.sh
;;
"c"|"C")
read -p "Enter the name of the consumer: " consumer_name1
curl -X POST "http://127.0.0.1:8001/consumers/$consumer_data1/acls" --data "group=Prod-AccessGroup"
bash ./kong_new_client.sh
;;
"d"|"D")
read -p "Enter the name of the consumer: " consumer_name2
# display API key
key=$(curl -X GET --url "http://localhost:8001/consumers/$consumer_data2/key-auth/")
key1=$(echo "$key" | cut -d'"' -f 10)
bash ./kong_new_client.sh
;;




"z"|"Z")
exit
;;

*)
echo "invalid answer, please try again"
;;

esac
done
