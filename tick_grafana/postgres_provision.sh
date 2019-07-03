#!/bin/bash

## YUM UPDATE
#yum -y update

## INSTALL POSTGRES YUM & EPEL REPOS
yum -y install https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm  epel-release

## INSTALL UTILITIES
yum -y install vim ntp

## INSTALL POSTGRES
yum -y install postgresql10 postgresql10-server postgresql10-libs postgresql10-contrib postgresql10-devel

## CHANGE DEFAULT DATA DIRECTORY
mkdir -p /db/postgresql/10/data
chown -R postgres:postgres /db
chmod -R 0700 /db


## CREATE LOG FILE LOCATION
mkdir -p /log/postgresql/10
chown -R postgres:postgres /log
chmod -R 0744 /log
q

## CREATE OVERIDING SYSTEMD FILE > POSTGRESQL
echo ".include /lib/systemd/system/postgresql-10.service
[Service]
Environment=PGDATA=/db/postgresql/10/data" >> /etc/systemd/system/postgresql-10.service


## INITIALISE POSTGRES
/usr/pgsql-10/bin/postgresql-10-setup initdb

#UPDATE postgresql.conf CONFIGS
echo "
## UPDATED SETTINGS
listen_addresses = '*'
#archive_mode = on
#archive_command = '/bin/true'" >> /db/postgresql/10/data/postgresql.conf

## UPDATE HOSTS FILE
echo "
##  TESTING
192.168.56.101 pgserver
192.168.56.102 pgserver2
192.168.56.103 influxdb
192.168.56.104 grafana " >> /etc/hosts


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



## START POSTGRES
systemctl enable postgresql-10.service
systemctl start postgresql-10.service

sudo -u postgres psql -c "create user mike login password 'jocasta' ; "
sudo -u postgres psql -c "create database mike owner mike; "


## ADD INFLUXDB  REPO
echo '[influxdb]
name = InfluxDB Repository - RHEL $releasever
baseurl = https://repos.influxdata.com/rhel/$releasever/$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key ' > /etc/yum.repos.d/influxdb.repo


## INSTALL INFLUXDB
yum -y install telegraf


## START / ENABLE telegraf
systemctl enable telegraf
systemctl start telegraf


## SYNC THE SERVER CLOCK
systemctl enable ntpd
ntpdate pool.ntp.org
systemctl start ntpd



exit
