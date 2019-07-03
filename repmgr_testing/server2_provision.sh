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
#/usr/pgsql-10/bin/postgresql-10-setup initdb

## ADD CONFIGS
#echo "
## UPDATED SETTINGS
##listen_addresses = '*' " >> /db/postgresql.conf


## UPDATE HOSTS FILE
echo "
## REPMGR TESTING
192.168.56.101 server1
192.168.56.102 server2" >> /etc/hosts


## ENABLE AND START POSTGRES
#systemctl enable postgresql-10.service
#systemctl start postgresql-10.service




exit



