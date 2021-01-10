#!/bin/bash
# After the PostgreSQL Docker entrypoint has called initdb to create
# the postgres user and database, it runs .sh and .sql files in
# docker-entrypoint-initdb.d/, i.e. this file.
# See: https://github.com/docker-library/docs/tree/master/postgres#how-to-extend-this-image

set -e


# Create a Talkyard user, and a replication user.
# ------------------------

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<EOF
create user talkyard password '$POSTGRES_PASSWORD';
create database talkyard;
grant all privileges on database talkyard to talkyard;

create user repl replication login connection limit 1 encrypted password '$POSTGRES_PASSWORD';
EOF


# Create test users: talkyard_test,  keycloak_test
# ------------------------

if [ -n "$CREATE_TEST_USER" ]; then
  # For running Talkyard's integration tests.
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<EOF
  create user talkyard_test password 'public';
  create database talkyard_test;
  grant all privileges on database talkyard_test to talkyard_test;
EOF

  # For testing OIDC login via Keycloak — seems importing a Keycloak realm
  # won't work with the h2 database; needs sth like Postgres. [ty_kc_db]
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<EOF
  create user keycloak_test password 'public';
  create database keycloak_test owner keycloak_test;
  grant all privileges on database keycloak_test to keycloak_test;
EOF
fi


# Let the replication user connect and replicate
# ------------------------

# `sed -i '/pattern/i...` inserts before the pattern. If inserted after
# "host all all" then apparently it'd have no effect.
sed -i '/host all all 0.0.0.0/i \
host replication repl 0.0.0.0/0 md5' $PGDATA/pg_hba.conf


# Streaming replication and logging
# ------------------------

cat << EOF >> $PGDATA/postgresql.conf

#======================================================================
# EDITED SETTINGS
#======================================================================

# Enable streaming replication from this server
#--------------------------

wal_level = hot_standby

# Each is 16 MB, this means almost 1 GB in total.
wal_keep_segments = 60

# More than 1 in case a connection gets orphaned until wal_sender_timeout
max_wal_senders = 4

# Not needed; we keep & copy WAL segments in pg_xlog instead.
# archive_mode = on
# archive_command = ...

hot_standby = on

# Logging
#--------------------------

logging_collector = off

# Don't use the default, /var/lib/postgresql/data/pg_log/, because then when mounting
# the logs at /var/log/postgresql on the *host* (so that standard Postgres monitoring
# tools will find the logs), Postgres will refuse to create the database, because
# data/ wouldn't be empty — pg_log/ would be inside.
log_directory = '/var/log/postgresql/'

log_rotation_age = 1d     # defualt = 1d
log_rotation_size = 50MB  # default = 10MB

# Logs statements running at least this number of milliseconds.
log_min_duration_statement = 2000

# %m = timestamp with milliseconds, %c = session id, %x = transaction id.
log_line_prefix = '%m session-%c tx-%x: '

# Log all data definition statements, such as CREATE, ALTER, and DROP.
log_statement = 'ddl'

EOF


# Help file about how to rsync to standby
# ------------------------

cat << EOF > $PGDATA/how-rsync-to-standby.txt
# Docs:
# - https://wiki.postgresql.org/wiki/Binary_Replication_Tutorial
# - https://wiki.postgresql.org/wiki/Streaming_Replication#How_to_Use

# rsync to the standby like so:
# 1) Stop Postgres on the going-to-become standby.
# 2) Rename recovery.conf.disabled or recovery.done to recovery.conf, on the standby.

# 3) rsync:
psql postgres postgres -c "SELECT pg_start_backup('rsync to standby ' || now(), true)"
rsync -acv $PGDATA/ $PEER_HOST:$PGDATA/ --exclude pg_xlog --exclude postmaster.pid --exclude recovery* --exclude failover_trigger_file --exclude backup_label
psql postgres postgres -c "SELECT pg_stop_backup()"

# 4) Optionally: (if too much data has been written to the db during the start-stop-backup above)
rsync -acv $PGDATA/pg_xlog $PEER_HOST:$PGDATA/

# 5) Start the standby.
EOF


# Configure streaming replication *to* this server
# ------------------------
# But don't enable it.

cat << EOF >> $PGDATA/recovery.conf.disabled
# See https://wiki.postgresql.org/wiki/Streaming_Replication, step 10.
# Don't forget to edit the primary_conninfo.

standby_mode   = 'on'
primary_conninfo = 'host=$PEER_HOST port=$PEER_PORT user=repl password=$PEER_PASSWORD'
trigger_file = '$PGDATA/failover_trigger_file'
EOF
