#!/bin/bash

## YUM UPDATE
#yum -y update


## UPDATE HOSTS FILE
echo "
192.168.56.101 pgserver
192.168.56.102 pgserver2
192.168.56.103 influxdb
192.168.56.104 grafana" >> /etc/hosts

## Install Utilities 
yum -y install vim ntp

## ADD GRAFANA REPO
echo '[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt' > /etc/yum.repos.d/grafana.repo

## PACAKGES FOR GRAFANA
yum -y install initscripts fontconfig freetype* urw-fonts

## INSTALL GRAFANA
yum -y install grafana

systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

## ADD INFLUXDB REPO
echo '[influxdb]
name = InfluxDB Repository - RHEL $releasever
baseurl = https://repos.influxdata.com/rhel/$releasever/$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key ' > /etc/yum.repos.d/influxdb.repo

## INSTALL telegraf
yum -y install telegraf

## START / ENABLE influxdb
systemctl enable telegraf
systemctl start telegraf

## SYNC THE SERVER CLOCK
systemctl enable ntpd
ntpdate pool.ntp.org
systemctl start ntpd



exit



