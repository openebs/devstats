#!/bin/bash
if [ -z "$IDB_HOST" ]
then
  IDB_HOST=localhost
fi
if [ -z "$IDB_PASS" ]
then
  echo "$0: you need to set IDB_PASS ebvironment variable"
  exit 1
fi
function finish {
    rm -rf "$PROJDB.dump" >/dev/null 2>&1
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
echo "restarting influxdb"
service influxdb restart || exit 2
echo "restarting postgresql"
service postgresql restart || exit 3
echo -n "waiting for postgres to respond..."
while true
do
  exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = 'devstats'"`
  if [ "$exists" = "1" ]
  then
    break
  fi
  sleep 1
  echo -n "."
done
echo "ok"
echo -n "waiting for influxdb to respond..."
while true
do
  exists=`echo 'show databases' | influx -host $IDB_HOST -username gha_admin -password $IDB_PASS 2>/dev/null`
  if [ ! -z "$exists" ]
  then
    break
  fi
  sleep 1
  echo -n "."
done
echo "ok"
