#!/bin/sh
# Corre una sola vez, cuando el volumen de Postgres esta vacio.
# Cada base tiene su propio usuario dueno y nadie mas puede conectarse a ella.
set -eu

psql -v ON_ERROR_STOP=1 --username postgres \
  -v conf_pass="$PG_CONFIG_PASSWORD" \
  -v firm_pass="$PG_SIGNER_PASSWORD" <<'SQL'
CREATE ROLE config LOGIN PASSWORD :'conf_pass';
CREATE DATABASE config OWNER config;
REVOKE CONNECT ON DATABASE config FROM PUBLIC;

CREATE ROLE signer LOGIN PASSWORD :'firm_pass';
CREATE DATABASE signer OWNER signer;
REVOKE CONNECT ON DATABASE signer FROM PUBLIC;
SQL
