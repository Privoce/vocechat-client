-- Tables for general information, not user-specific.

-- Server records.
create table if not exists server (
    -- serverId returned by backend. Only available after a successful login.
    id text primary key, 

    -- The logo of the server.
    logo BLOB NOT NULL,

    -- The full url of the server, including scheme and port.
    url text not null,

    -- Server name + description
    org_info text not null,

    -- Common info
    common_info text not null,

    created_at integer not null,
    updated_at integer not null
);

create table if not exists account (
    -- server id, the same as server.id. Provided by server. Only available after a successful login.
    id text primary key,

    -- The user id of the account.
    uid integer not null,

    -- The user info of the account.
    info text not null,

    token text not null,
    refresh_token text not null,
    expired_in integer not null,

    -- users version, provided by server. Default to 0.
    users_version integer not null,

    -- max mid, provided by server. Default to 0.
    max_mid integer not null,

    -- status of account. 0: logged out; 1: logged in.
    status integer not null,

    created_at integer not null
);
