#!/bin/bash

## RELAX VAGRANT HOME FOLDER PERMISSIONS
chmod 777 /home/vagrant

## YUM UPDATE
#yum -y update

## INSTALL POSTGRES YUM & EPEL REPOS
yum -y install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm  epel-release

## INSTALL UTILITIES
yum -y install vim ntp

## INSTALL POSTGRES
yum -y install postgresql10 postgresql10-server postgresql10-libs postgresql10-contrib postgresql10-devel

## INSTALL REPMANAGER
yum -y install repmgr10

## CHANGE DEFAULT DATA DIRECTORY
mkdir -p /db/postgresql/10/data
chown -R postgres:postgres /db
chmod -R 0700 /db


## CREATE LOG FILE LOCATION
mkdir -p /log/postgresql/10
mkdir -p /log/repmgr/10
touch /log/repmgr/10/repmgr_event_notification.log
chown -R postgres:postgres /log
chmod -R 0744 /log


## CREATE OVERIDING SYSTEMD FILE > POSTGRESQL
echo ".include /lib/systemd/system/postgresql-10.service
[Service]
Environment=PGDATA=/db/postgresql/10/data" >> /etc/systemd/system/postgresql-10.service

## CREATE OVERIDING SYSTEMD FILE > REPMGR
echo ".include /lib/systemd/system/repmgr10.service
[Service]
Environment=REPMGRDCONF=/etc/repmgr.conf" >> /etc/systemd/system/repmgr10.service



## INITIALISE POSTGRES
/usr/pgsql-10/bin/postgresql-10-setup initdb

#UPDATE postgresql.conf CONFIGS
echo "
## UPDATED SETTINGS
listen_addresses = '*'
archive_mode = on
archive_command = '/bin/true'
shared_preload_libraries = 'repmgr'" >> /db/postgresql/10/data/postgresql.conf

## UPDATE pg_hba.conf
echo "
#### REPMGR ########################################################
local   replication   repmgr                         trust
host    replication   repmgr    192.168.56.101/32    trust
host    replication   repmgr    192.168.56.102/32    trust
host	replication   repmgr    192.168.56.103/32    trust
host    replication   repmgr    192.168.56.104/32    trust

local   repmgr        repmgr                         trust
host    repmgr        repmgr    192.168.56.101/32    trust
host    repmgr        repmgr    192.168.56.102/32    trust
host    repmgr	      repmgr    192.168.56.103/32    trust
host    repmgr        repmgr    192.168.56.104/32    trust" >> /db/postgresql/10/data/pg_hba.conf


## UPDATE HOSTS FILE
echo "
## REPMGR TESTING
192.168.56.101 node-1
192.168.56.102 node-2
192.168.56.103 node-3
192.168.56.103 node-4" >> /etc/hosts


## CREATE PGSQL_PROFILE
echo "
# User specific environment and startup programs

PATH=$PATH:$HOME/bin
export PATH
unset USERNAME
set -o vi
export PATH=/usr/pgsql-10/bin:/usr/pgsql-10/lib:/usr/bin:/bin:/sbin:/usr/sbin:/usr/local/bin:$HOME/bin:
## PostgreSQL data location
export PGPORT=5432
export PGDATA=/db/postgresql/10/data
export PS1=\$LOGNAME:'\$PWD>'
" >> /var/lib/pgsql/.pgsql_profile
chown postgres:postgres /var/lib/pgsql/.pgsql_profile



## START POSTGRES IF MASTER + CREATE REPMGR DB AND USER
if [ "$1" -eq "1" ] ; then

systemctl enable postgresql-10.service
systemctl start postgresql-10.service

sudo -u postgres psql -c "create user repmgr superuser; "
sudo -u postgres psql -c "create database repmgr owner repmgr; "


fi


## ADD REPMGR USER, DATABASE and CONFIG FILE

sudo -u postgres -H bash << EOF  >> /etc/repmgr.conf

# USER DEFINED REPMGR SETTINGS

echo "node_id=$1
node_name=node-$1
conninfo='host=192.168.56.10$1 user=repmgr dbname=repmgr connect_timeout=2'
data_directory='/db/postgresql/10/data'
pg_bindir='/usr/pgsql-10/bin'
use_replication_slots=true

log_file=/log/repmgr/10/repmgr.log

service_start_command = 'sudo systemctl start postgresql-10'
service_stop_command = 'sudo systemctl stop postgresql-10'
service_restart_command = 'sudo systemctl restart postgresql-10'
service_reload_command = 'sudo systemctl reload postgresql-10'

## repmgrd ########
failover=automatic
promote_command='/usr/pgsql-10/bin/repmgr standby promote --verbose --log-to-file'
follow_command='/usr/pgsql-10/bin/repmgr standby follow --verbose  --log-to-file --upstream-node-id=%n'
monitoring_history=yes
monitor_interval_secs=5  ## default 2

event_notification_command='/etc/repmgr/scripts/repmgr_event_notification.sh %n %e %s \"%t\" \"%d\" %p \"%c\" \"%a\" ' " 

EOF

chown postgres:postgres /etc/repmgr.conf

############################################


## ADD Event Notification Script for REPMGR
mkdir /etc/repmgr/scripts
cat << 'EOF' > /etc/repmgr/scripts/repmgr_event_notification.sh
#!/bin/bash

echo "$1 $2 $3 $4 $5 $6 $7 $8 $9" >> /log/repmgr/10/repmgr_event_notification.log

EOF

chmod 744 /etc/repmgr/scripts/repmgr_event_notification.sh
chown -R postgres:postgres /etc/repmgr/


## INSERT LOGROTATE FILE FOR REPMGR.LOG
cat << EOF > /etc/logrotate.d/repmgr
/log/repmgr/10/repmgr.log {
	missingok
        compress
        rotate 52
        maxsize 100M
        weekly
        create 0600 postgres postgres
    }
EOF



## ALLOW SYSTEMD PERMISSIONS FOR REPMGR / POSTGRES

touch /etc/sudoers.d/postgres
echo "postgres ALL = NOPASSWD: /usr/bin/systemctl stop postgresql-10, \
/usr/bin/systemctl start postgresql-10, \
/usr/bin/systemctl restart postgresql-10, \
/usr/bin/systemctl reload postgresql-10 " >> /etc/sudoers.d/postgres
chmod 440 /etc/sudoers.d/postgres


## REGISTER PRIMARY ( OR CLONE AND REGISTER STANDBY )
if [ "$1" -eq "1" ] ; then

sudo -u postgres  /usr/pgsql-10/bin/repmgr primary register

else

sudo -u postgres mv /db/postgresql/10 /db/postgresql/10.old
sudo -u postgres  /usr/pgsql-10/bin/repmgr -h 192.168.56.101 -U repmgr -d repmgr standby clone

systemctl enable postgresql-10.service
systemctl start postgresql-10.service

sudo -u postgres  /usr/pgsql-10/bin/repmgr standby register

fi


## REINSTATE VAGRANT HOME FOLDER PERMISSIONS
chmod 700 /home/vagrant

echo "VARIABLE IS: $1 " >> /home/vagrant/tester.txt


### SSH - THIS IS A HACK PROBABLY A BETTER WAY :)


mkdir /var/lib/pgsql/.ssh


echo "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA0kBY4MbKgYceMKVHMr3EY6HiWy+2ktGJ5ui62wWDkX5evvJ2
Djwcj9FpEjLt9dS/4RoIr0qwiF4yjNfYdoTn8F88REe2/++nQFX9wGVSf0dRnt1P
Cu8kBMsTHkEZZYRfjTZN4kpKugMItFZt7GrQztKbNK8TJqzb7UIqKje3gxzGyj1d
OwihzBPNtipS32cNmHlT0p2KOHgI2OrFI81sM6TZMOChIDhIIYQxo9cls/sC3pl5
ESd2J2wO/qVhN9a5eTGglTRE0o6VX4P9RJ8C7/meVO+Qj4SyGgC7zOCSoqZ3BC96
uRF0wKBnc16O/ggGsXwy+Y9tyVy7bsxBBnCq3QIDAQABAoIBAGDzIwijIgYQVC+C
Rw5yyvhWUZZSrhGNZdWAQ4lzRXP1naLXEvEFbvYyTg0CRxAwhjo6Uv7hpf170jt3
3GzqZDlG8PdbSltCGxFjlZr+HchrDov+6M/V7fn32lz9D8TsAVOQUuGh+EtF0uG1
aQK3TonQO5lTkbUnyFHjTKYjAxAFgiV6Eqab54PgFiO66hHnuahN/vk7MhyO+YgO
hceaj5bn209DmY4SHPDG6RcBRQYD/Rpvuuh28HzvLoDFhrAVQEDVOg4OBlJQFz2n
Vz0agSmv7IoortwF+7lMzpt14bOLXu7f6HJPq0XUBmhljoNVEySq4aT/oFaQjyR8
PcJSwIECgYEA/Z/HOlCBB7RtZslC3LzAah5gRNOhry97Vc17JDQGprPyK1/6yr4P
JKXSY/iURJl1l8sOglQURhj3WjzcwMnSY8Kzi8DfyOz+s2Vp4O4fgP2uYKJjKeBK
Ox9VFfAqYGq0g95Lv4eKtMxyx9AihER6jlt6CND0y+kbb9eDSRcCJmUCgYEA1DiO
QuXMTWmwR4QFiTSg6m56cyHd6C874H4Racm4i/MupRTHRDCoYnNcMchQgDLxjWGS
k5cBsfAqZsEjv2MJ7EeKfh2fTGvTxliVv7oSJFradBCi5Ft95dKUigpZtu7ytUoF
SHDJ1BGYoUKyaTAv2/FRxkRg+55Ou6xVLpHfDxkCgYEA3zDheS7pLaeY8vBAN9Kf
HYPXwhnfWjRVvD9Uk5p5E/CdN5CCOjKhTuXiTPmvOOM3ObqG7Sgio0FLQ4z1026I
CCSKLn0wMjhlN+gSEdBbxv73mrCsxWhMytSa4vBzyl98teNFE6qq5MpaY/6EsZM1
qttTfDiuhFeCPp0QOpzV1oUCgYAcZvFLLLwaBDIOcDHZegyrM1v5+qdbQq8NzXGB
Kfkj6cjtWQmOK8DtZCkLlJaJgcfoNw3J6OTWLqFOHT0uiQ+z6qMzW72NGcU+/24T
OdDhwrMH444ZZ9FCp9svWlFFdVdQQfbRCh9I3Y4Czw1XnJZbJkHeehpMspQw89B2
qhkjSQKBgC6hjVel2EmxHHtB0GurjSL1vPZHQHf5aHs8TuEe87lfcmOP8ZgAVcsm
RLlQFt/llvFIhoqThad9EiMPuJ1BR9MqWLpiZmLRO5DAR/8tMGBaSdh6yxKadAe1
0Y3phDrjPRIW9yeReIuZCXBRUAvCEe5ee4cLH2JcAE2Lqe36msZH
-----END RSA PRIVATE KEY-----" >>  /var/lib/pgsql/.ssh/id_rsa

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSQFjgxsqBhx4wpUcyvcRjoeJbL7aS0Ynm6LrbBYORfl6+8nYOPByP0WkSMu311L/hGgivSrCIXjKM19h2hOfwXzxER7b/76dAVf3AZVJ/R1Ge3U8K7yQEyxMeQRllhF+NNk3iSkq6Awi0Vm3satDO0ps0rxMmrNvtQioqN7eDHMbKPV07CKHME822KlLfZw2YeVPSnYo4eAjY6sUjzWwzpNkw4KEgOEghhDGj1yWz+wLemXkRJ3YnbA7+pWE31rl5MaCVNETSjpVfg/1EnwLv+Z5U75CPhLIaALvM4JKipncEL3q5EXTAoGdzXo7+CAaxfDL5j23JXLtuzEEGcKrd postgres@node-$1" >>  /var/lib/pgsql/.ssh/id_rsa.pub


## CREATE SSH CONFIG FILE TO SWITCH OFF HOSTCHECKING 
echo "Host *
	StrictHostKeyChecking no" >> /var/lib/pgsql/.ssh/config

## ADD PUBLIC KEY TO AUTHORISED KEYS
for f in 1 2 3 4
do

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSQFjgxsqBhx4wpUcyvcRjoeJbL7aS0Ynm6LrbBYORfl6+8nYOPByP0WkSMu311L/hGgivSrCIXjKM19h2hOfwXzxER7b/76dAVf3AZVJ/R1Ge3U8K7yQEyxMeQRllhF+NNk3iSkq6Awi0Vm3satDO0ps0rxMmrNvtQioqN7eDHMbKPV07CKHME822KlLfZw2YeVPSnYo4eAjY6sUjzWwzpNkw4KEgOEghhDGj1yWz+wLemXkRJ3YnbA7+pWE31rl5MaCVNETSjpVfg/1EnwLv+Z5U75CPhLIaALvM4JKipncEL3q5EXTAoGdzXo7+CAaxfDL5j23JXLtuzEEGcKrd postgres@node-$f" >>  /var/lib/pgsql/.ssh/authorized_keys


done


chown -R postgres:postgres /var/lib/pgsql/.ssh
chmod 0700 /var/lib/pgsql/.ssh
chmod 600 /var/lib/pgsql/.ssh/id_rsa
chmod 644 /var/lib/pgsql/.ssh/id_rsa.pub
chmod 644 /var/lib/pgsql/.ssh/authorized_keys
chmod 400 /var/lib/pgsql/.ssh/config
sudo /sbin/restorecon -r /var/lib/pgsql/.ssh


## SYNC THE SERVER CLOCK
systemctl enable ntpd
ntpdate pool.ntp.org
systemctl start ntpd


## ENABLE REPMGRD - START MONITORING TOOL
systemctl enable repmgr10
systemctl start repmgr10


exit
