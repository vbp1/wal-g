#!/bin/sh
set -e -x

CONFIG_FILE="/tmp/configs/delta_backup_wal_delta_test_config.json"
COMMON_CONFIG="/tmp/configs/common_config.json"
TMP_CONFIG="/tmp/configs/tmp_config.json"
cat ${CONFIG_FILE} > ${TMP_CONFIG}
echo "," >> ${TMP_CONFIG}
cat ${COMMON_CONFIG} >> ${TMP_CONFIG}
/tmp/scripts/wrap_config_file.sh ${TMP_CONFIG}


/usr/lib/postgresql/12/bin/initdb ${PGDATA}

echo "archive_mode = on" >> /var/lib/postgresql/12/main/postgresql.conf
echo "archive_command = '/usr/bin/timeout 600 /usr/bin/wal-g --config=${TMP_CONFIG} wal-push %p && mkdir -p /tmp/deltas/$(basename %p)'" >> /var/lib/postgresql/12/main/postgresql.conf
echo "archive_timeout = 600" >> /var/lib/postgresql/12/main/postgresql.conf

/usr/lib/postgresql/12/bin/pg_ctl -D ${PGDATA} -w start

/tmp/scripts/wait_while_pg_not_ready.sh

wal-g --config=${TMP_CONFIG} delete everything FORCE --confirm

#pgbench -i -f /tmp/sql/init.sql -s 10 postgres
psql -f /tmp/sql/init.sql
psql -f /tmp/sql/check_toast.sql

pgbench -c 10 -f /tmp/sql/transactions.sql -t 10000 --no-vacuum || true
psql -f /tmp/sql/check_toast.sql

wal-g --config=${TMP_CONFIG} backup-push ${PGDATA}

pgbench -c 2 -f /tmp/sql/transactions.sql -T 10000 --no-vacuum &
sleep 3

for i in 1 2 3
do
  start_lsn=$(psql -Atc "SELECT pg_current_wal_lsn();")
  pgbench -c 10 -f /tmp/sql/transactions.sql -t 40000 --no-vacuum || true
  sleep 1
  end_lsn=$(psql -Atc "SELECT pg_current_wal_lsn();")
  wal_volume=$(psql -Atc "SELECT pg_size_pretty(pg_wal_lsn_diff('$end_lsn', '$start_lsn'));")
  echo "WAL Volume: $wal_volume"
  wal-g --config=${TMP_CONFIG} backup-push ${PGDATA}
done

psql -f /tmp/sql/check_toast.sql

pg_dumpall -f /tmp/dump1


#sleep 3600

/tmp/scripts/drop_pg.sh

wal-g --config=${TMP_CONFIG} backup-fetch ${PGDATA} LATEST

echo "restore_command = 'echo \"WAL file restoration: %f, %p\"&& /usr/bin/wal-g --config=${TMP_CONFIG} wal-fetch \"%f\" \"%p\"'" >>/var/lib/postgresql/12/main/postgresql.conf
touch /var/lib/postgresql/12/main/recovery.signal


/usr/lib/postgresql/12/bin/pg_ctl -D ${PGDATA} -w start
/tmp/scripts/wait_while_pg_not_ready.sh
pg_dumpall -f /tmp/dump2

# diff /tmp/dump1 /tmp/dump2

psql -f /tmp/scripts/amcheck.sql -v "ON_ERROR_STOP=1" postgres > /dev/null
/tmp/scripts/drop_pg.sh
rm ${TMP_CONFIG}
