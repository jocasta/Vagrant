#!/bin/bash

## RELAX VAGRANT HOME FOLDER PERMISSIONS
chmod 777 /home/vagrant

## YUM UPDATE
#yum -y update

## INSTALL POSTGRES YUM & EPEL REPOS
yum -y install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm  epel-release

## INSTALL UTILITIES
yum -y install vim

## INSTALL POSTGRES
yum -y install postgresql10 postgresql10-server postgresql10-libs postgresql10-contrib postgresql10-devel

## INSTALL REPMANAGER
yum -y install repmgr10

## CHANGE DEFAULT DATA DIRECTORY
mkdir -p /db/postgresql/10/
chown -R postgres:postgres /db
chmod -R 0700 /db


## CREATE LOG FILE LOCATION
mkdir -p /log/postgresql/10
chown -R postgres:postgres /log
chmod -R 0744 /log


## CREATE OVERIDING SYSTEMD FILE
echo ".include /lib/systemd/system/postgresql-10.service
[Service]
Environment=PGDATA=/db/postgresql/10" >> /etc/systemd/system/postgresql-10.service

## INITIALISE POSTGRES
/usr/pgsql-10/bin/postgresql-10-setup initdb

## UPDATE postgresql.conf CONFIGS
echo "
## UPDATED SETTINGS
listen_addresses = '*'
archive_mode = on
archive_command = '/bin/true' " >> /db/postgresql/10/postgresql.conf

## UPDATE pg_hba.conf
echo "
#### REPMGR ########################################################
local   replication   repmgr                         md5
host    replication   repmgr    192.168.56.101/32    md5
host    replication   repmgr    192.168.56.102/32    md5
host	replication   repmgr    192.168.56.103/32    md5

local   repmgr        repmgr                         md5
host    repmgr        repmgr    192.168.56.101/32    md5
host    repmgr        repmgr    192.168.56.102/32    md5
host    repmgr	      repmgr    192.168.56.103/32    md5" >> /db/postgresql/10/pg_hba.conf

## REMOVE peer from pg_hba.conf
sed -i -e 's/peer/md5/g' /db/postgresql/10/pg_hba.conf


## UPDATE HOSTS FILE
echo "
## REPMGR TESTING
192.168.56.101 server1
192.168.56.102 server2
192.168.56.103 server3" >> /etc/hosts


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
export PGDATA=/db/postgresql/10
export PS1=\$LOGNAME:'\$PWD>'
" >> /var/lib/pgsql/.pgsql_profile
chown postgres:postgres /var/lib/pgsql/.pgsql_profile


## ENABLE AND START POSTGRES
systemctl enable postgresql-10.service
systemctl start postgresql-10.service



## ADD REPMGR USER AND DATABASE

sudo -u postgres -H bash << EOF

# Put your current script commands here
psql -c "create user repmgr superuser password 'test' ; "
psql -c "create database repmgr owner repmgr; "

EOF


## REINSTATE VAGRANT HOME FOLDER PERMISSIONS
chmod 700 /home/vagrant

echo "VARIABLE IS: $1 " >> /home/vagrant/tester.txt


exit



