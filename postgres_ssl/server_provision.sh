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

## CHANGE DEFAULT DATA DIRECTORY
mkdir -p /db/postgresql/10/data
chown -R postgres:postgres /db
chmod -R 0700 /db


## CREATE LOG FILE LOCATION
mkdir -p /log/postgresql/10
chown -R postgres:postgres /log
chmod -R 0744 /log


## CREATE OVERIDING SYSTEMD FILE > POSTGRESQL
echo ".include /lib/systemd/system/postgresql-10.service
[Service]
Environment=PGDATA=/db/postgresql/10/data" >> /etc/systemd/system/postgresql-10.service


## INITIALISE POSTGRES
/usr/pgsql-10/bin/postgresql-10-setup initdb


################################################################################################
## CREATE SSL CERTIFICATES (self-signed RootCA + Server) 
################################################################################################

## CREATE CA DIRECTORY #######################
mkdir /root/ssl

## rootCA.key
openssl genrsa -out /root/ssl/mike-rootCA.key 2048
chmod 640 /root/ssl/mike-rootCA.key

## rootCA.crt
openssl req -x509 -new -key /root/ssl/mike-rootCA.key -days 10000 -subj "/C=UK/ST=Scotland/L=Edinburgh/O=test/CN=node-$1"  -out /root/ssl/mike-rootCA.crt


### CONFIGURE POSTGRESQL SERVER (as user postgres)  #####

## Create postgres server key and signing request
openssl req -new -nodes -text -out /db/postgresql/10/data/server.csr -keyout /db/postgresql/10/data/server.key -subj "/CN=postgres"
chown postgres:postgres /db/postgresql/10/data/server.*
chmod 600 /db/postgresql/10/data/server.key

## Sign PostgreSQL-server key with CA private key
openssl x509 -req -in /db/postgresql/10/data/server.csr -text -days 365 -CA /root/ssl/mike-rootCA.crt -CAkey /root/ssl/mike-rootCA.key -CAcreateserial -out /db/postgresql/10/data/server.crt

chown postgres:postgres /db/postgresql/10/data/server.crt

## Create root cert = PostgreSQL-server cert + CA cert
cat /db/postgresql/10/data/server.crt  /root/ssl/mike-rootCA.crt > /db/postgresql/10/data/root.crt
chown postgres:postgres /db/postgresql/10/data/root.crt

####################################################################################################################
####################################################################################################################



#UPDATE postgresql.conf CONFIGS
echo "
## UPDATED SETTINGS
listen_addresses = '*'
ssl = on
ssl_ca_file = 'root.crt'
#archive_mode = on
#archive_command = '/bin/true'" >> /db/postgresql/10/data/postgresql.conf

## UPDATE HOSTS FILE
echo "
##  TESTING
192.168.56.101 node-1
192.168.56.102 node-2
192.168.56.103 node-3
192.168.56.104 node-4
192.168.56.105 node-5
192.168.56.106 node-6" >> /etc/hosts


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
systemctl enable postgresql-10.service
systemctl start postgresql-10.service

sudo -u postgres psql -c "create user mike login password 'jocasta' ; "
sudo -u postgres psql -c "create database mike owner mike; "



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
for f in 5 6
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



exit
