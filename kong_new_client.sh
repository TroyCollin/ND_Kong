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
echo " This script will Clean up Audit directoy /var/log/Audit"
echo " Script checkes size of free space % on /var/log/audit then check if it's over 90%"
echo " If over 90%, it will compress all audit into tar.gz and remove old files"
echo " Old audit.tar.gz will be renamed to audit.tar.gz.backup for auditing purposes"
echo " If system can't clean its self an Alert will be sent"
echo ""
echo ""
