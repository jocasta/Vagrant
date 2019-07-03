#!/bin/bash
#
#	GENERATE SSL CERTS
#	
#

SERVER=$1

if [[ $# -eq 0 ]] ; then
    echo 'You need to specify the server you wish to generate SSL certs for'
    exit 0
fi

BASE_DIR="/var/certs/$SERVER"

echo "Creating directory $BASE_DIR"
if [ -d $BASE_DIR ]; then
  echo "$BASE_DIR already exists!"
  echo "If you really want to recreate certs for $SERVER, please remove or rename it"
  exit 1
else
  mkdir -p $BASE_DIR
fi


## ROOT ###########################################################

## CREATE CA DIRECTORY #######################


## rootCA.key
openssl genrsa -out mike-rootCA.key 2048
chmod 640 mike-rootCA.key

## rootCA.crt
openssl req -x509 -new -key mike-rootCA.key -days 10000 -subj '/C=UK/ST=Scotland/L=Edinburgh/O=test/CN=node-5'  -out mike-rootCA.crt

###################################################################


### CONFIGURE POSTGRESQL SERVER (as user postgres)  #####

## Create postgres server key and signing request
openssl req -new -nodes -text -out server.csr -keyout server.key -subj "/CN=postgres"
chmod 600 server.key


## Sign PostgreSQL-server key with CA private key
openssl x509 -req -in /db/postgresql/10/data/server.csr -text -days 365 -CA /root/ssl/mike-rootCA.crt -CAkey /root/ssl/mike-rootCA.key -CAcreateserial -out /db/postgresql/10/data/server.crt

chown postgres:postgres /db/postgresql/10/data/server.crt

## Create root cert = PostgreSQL-server cert + CA cert
cat /db/postgresql/10/data/server.crt  /root/ssl/mike-rootCA.crt > /db/postgresql/10/data/root.crt
chown postgres:postgres /db/postgresql/10/data/root.crt 

## Grant access
CREATE role sslcertusers;
ALTER role sslcertusers ADD USER mike;

## NEED TO ADD ssl_ca_file in postgresql.conf
ssl_ca_file=root.crt


## CLIENT CERTIFICATES

## CREATE client-key (username as CN)
openssl req -new -nodes -text -out postgresql.csr -keyout postgresql.key -subj "/CN=mike"
chmod 600 postgresql.key


## Sign client key with CA private key
openssl x509 -req -in /var/lib/pgsql/.postgresql/postgresql.csr -text -days 365 -CA /root/ssl/mike-rootCA.crt -CAkey /root/ssl/mike-rootCA.key -CAcreateserial -out /var/lib/pgsql/.postgresql/server.crt


## 


