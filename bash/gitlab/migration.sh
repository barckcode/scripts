#!/bin/bash

# Configuración
OLD_GITLAB_DOMAIN="git.ejemplo.com"
GITLAB_DOMAIN="gitlab.ejemplo.com"
GITLAB_URL="https://$GITLAB_DOMAIN"
GITLAB_TOKEN="token-de-acceso-de-ejemplo"
GROUP_NAME="grupo-de-ejemplo"
PROJECT_NAME="proyecto-de-ejemplo"

# 1. Obtener/Crear el grupo
GROUP_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$GITLAB_URL/api/v4/groups/$GROUP_NAME" | jq '.id')

if [ "$GROUP_ID" == "null" ]; then
    echo "Creando grupo..."
    GROUP_ID=$(curl --silent --request POST \
        --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --header "Content-Type: application/json" \
        --data "{
            \"name\": \"$GROUP_NAME\",
            \"path\": \"$GROUP_NAME\",
            \"visibility\": \"private\"
        }" \
        "$GITLAB_URL/api/v4/groups" | jq '.id')
fi

# 2. Crear el proyecto
echo "Creando proyecto..."
curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
        \"name\": \"$PROJECT_NAME\",
        \"path\": \"$PROJECT_NAME\",
        \"namespace_id\": $GROUP_ID,
        \"visibility\": \"private\"
    }" \
    "$GITLAB_URL/api/v4/projects"

# 3. Clonar y pushear el repositorio
git clone --mirror git@$OLD_GITLAB_DOMAIN:$GROUP_NAME/$PROJECT_NAME.git
cd $PROJECT_NAME.git
git remote add new-gitlab git@$GITLAB_DOMAIN:$GROUP_NAME/$PROJECT_NAME.git
git push --mirror new-gitlab
