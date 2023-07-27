-- Tables for general information, not user-specific.

-- Server records.
create table if not exists chat_server (
    id text primary key,
    logo BLOB NOT NULL,
    url text not null,
    port integer not null,
    tls integer not null,
    server_id text not null,
    created_at integer not null,
    updated_at integer not null,
    properties text not null
    );

CREATE INDEX IF NOT EXISTS index_url ON chat_server(url);

-- An account could be found only with both chat_server_id and uid together.
-- [chat_server_id] is the [id] in [chat_server] table.
create table if not exists user_db (
    id text primary key,
    uid integer not null,
    info text not null,
    db_name text not null,
    chat_server_id text not null,
    created_at integer not null,
    updated_at integer not null,
    token text not null,
    refresh_token text not null,
    expired_in integer not null,
    logged_in integer not null,
    users_version integer not null,
    -- avatar_bytes BLOB not null,
    properties text not null,
    max_mid integer not null
);

CREATE INDEX IF NOT EXISTS index_chat_server_id ON user_db(chat_server_id);
CREATE INDEX IF NOT EXISTS index_uid ON user_db(uid);
CREATE INDEX IF NOT EXISTS index_logged_in ON user_db(logged_in);

CREATE TABLE IF NOT EXISTS status (
    id text primary key,
    user_db_id text not null
);
CREATE INDEX IF NOT EXISTS index_user_db_id ON status(user_db_id);