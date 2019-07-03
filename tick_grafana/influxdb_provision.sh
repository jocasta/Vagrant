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

## ADD REPO
echo '[influxdb]
name = InfluxDB Repository - RHEL $releasever
baseurl = https://repos.influxdata.com/rhel/$releasever/$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key ' > /etc/yum.repos.d/influxdb.repo

## INSTALL INFLUXDB
yum -y install influxdb telegraf

## START / ENABLE influxdb
systemctl enable influxdb
systemctl start influxdb

## START / ENABLE telegraf
systemctl enable telegraf
systemctl start telegraf


## SYNC THE SERVER CLOCK
systemctl enable ntpd
ntpdate pool.ntp.org
systemctl start ntpd




exit



