#!/bin/bash



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



