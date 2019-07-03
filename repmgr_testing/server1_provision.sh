#!/bin/bash

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

## CHANGE DEFAULT DIRECTORY
mkdir /db
chmod -R 0700 /db
chown postgres:postgres /db

## CREATE OVERIDING SYSTEMD FILE
echo ".include /lib/systemd/system/postgresql-10.service
[Service]
Environment=PGDATA=/db" >> /etc/systemd/system/postgresql-10.service

## INITIALISE POSTGRES
/usr/pgsql-10/bin/postgresql-10-setup initdb

## UPDATE postgresql.conf CONFIGS
echo "
## UPDATED SETTINGS
listen_addresses = '*'
archive_mode = on
archive_command = '/bin/true' " >> /db/postgresql.conf

## UPDATE pg_hba.conf
echo "
#### REPMGR ########################################################
local   replication   repmgr                         trust
host    replication   repmgr    192.168.56.101/32    trust
host    replication   repmgr    192.168.56.102/32    trust

local   repmgr        repmgr                         trust
host    repmgr        repmgr    192.168.56.101/32    trust
host    repmgr        repmgr    192.168.56.102/32    trust " >> /db/pg_hba.conf


## UPDATE HOSTS FILE
echo "
## REPMGR TESTING
192.168.56.101 server1
192.168.56.102 server2" >> /etc/hosts


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
export PGDATA=/db
#export PS1=$LOGNAME:'$PWD>'
" >> /var/lib/pgsql/.pgsql_profile
chown postgres:postgres /var/lib/pgsql/.pgsql_profile


## ENABLE AND START POSTGRES
systemctl enable postgresql-10.service
systemctl start postgresql-10.service




exit



