#!/bin/bash

DB_HOST=${DB_HOST:-postgres}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${POSTGRES_DB}
DB_USER=$POSTGRES_USER
DB_PASSWORD=$POSTGRES_PASSWORD

export PGPASSWORD=$POSTGRES_PASSWORD

echo "clean.sh: Nettoyage des données supprimées..."
echo "clean.sh: Connexion à PostgreSQL à l'aide de l'utilisateur $DB_USER sur $DB_HOST:$DB_PORT..."
echo "clean.sh: Nettoyage des données supprimées dans la base de données $DB_NAME..."
echo "clean.sh: password: $PGPASSWORD/$DB_PASSWORD"

psql -h $DB_HOST -U $POSTGRES_USER -d $POSTGRES_DB -p $DB_PORT <<-EOSQL
    DELETE FROM _friendship WHERE deleted_at IS NOT NULL;
    DELETE FROM _pong WHERE deleted_at IS NOT NULL;
    DELETE FROM _pongHistory WHERE deleted_at IS NOT NULL;
    DELETE FROM _emailActivation WHERE deleted_at IS NOT NULL;
    DELETE FROM _user WHERE deleted_at IS NOT NULL;
EOSQL

echo "Nettoyage des données supprimées effectué avec succès."

