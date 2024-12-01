#!/bin/bash

psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<-EOSQL
CREATE TABLE IF NOT EXISTS _user (
    id SERIAL PRIMARY KEY,
    username VARCHAR(12) NOT NULL,
    img_url VARCHAR(255) NOT NULL DEFAULT 'https://localhost/img/default.jpg',
    email VARCHAR(320) NOT NULL,
    password VARCHAR(255),
    role INTEGER,
    login_type INTEGER,
    restrict BOOLEAN DEFAULT FALSE,
    refresh_token VARCHAR(1024) DEFAULT NULL,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS unique_email_not_deleted
ON _user (email)
WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS _emailActivation (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES _user(id),
    token VARCHAR(6) NOT NULL,
    expire_at TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS _pong (
    id SERIAL PRIMARY KEY,
    player_1_id INTEGER REFERENCES _user(id),
    player_2_id INTEGER REFERENCES _user(id),
    type INTEGER,
    state INTEGER,
    rank_points INTEGER,
    player_1_score INTEGER,
    player_2_score INTEGER,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS _pongHistory (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES _user(id),
    nb_win INTEGER,
    nb_win_tournament INTEGER,
    nb_lose INTEGER,
    nb_game INTEGER,
    rank_points INTEGER,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS _friendship (
    id SERIAL PRIMARY KEY,
    requester_id INTEGER REFERENCES _user(id) ON DELETE CASCADE,
    receiver_id INTEGER REFERENCES _user(id) ON DELETE CASCADE,
    status VARCHAR(10) NOT NULL DEFAULT 'pending',
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS _tournament (
    id SERIAL PRIMARY KEY,
    host_id INTEGER REFERENCES _user(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    start_at TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

EOSQL

echo "Tables configurés avec succès."
