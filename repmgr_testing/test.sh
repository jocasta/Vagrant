#!/bin/bash

NUMBER="echo `hostname` | tail -c 1"


echo "node_name=`hostname`
conninfo='host=192.168.56.10$NUMBER user=repmgr dbname=repmgr connect_timeout=2'
data_directory='/db'
pg_bindir='/usr/pgsql-10/bin'
use_replication_slots=true

service_start_command = 'sudo systemctl start postgresql-10'
service_stop_command = 'sudo systemctl stop postgresql-10'
service_restart_command = 'sudo systemctl restart postgresql-10'
service_reload_command = 'sudo systemctl reload postgresql-10'
 " >> test_file


exit
