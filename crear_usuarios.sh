#!/bin/bash
# Author: Barckcode
# Description: Script to create users

NEW_PASSWORD="temporal"

while read username comment
do
    useradd -c "$comment" $username
    echo "**************************"
    echo "Has añadido este usuario:"
    grep $username /etc/passwd
    echo "************"
    echo "Estado de la nueva contraseña:"
    echo -e "$NEW_PASSWORD\n$NEW_PASSWORD" | passwd $username

# Syntax:
# Username Comment
# Example:
# admin User Administrator
done <<EOF
arthas Caballero de la muerte
illidan Cazador de demonios
thrall Hijo de Durotan
EOF
