#!/bin/bash

## YUM UPDATE
yum -y update


## EPEL-RELEASE
yum -y install epel-release yum -y update

## WEBTATIC
yum -y install epel-release
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y update
yum clean all


## YUM INSTALL UTILITIES
yum -y install httpd php72w php72w-curl php72w-openssl php72w-zip php72w-pecl-apcu php72w-gd  php72w-xml php72w-mbstring php72w-opcache wget unzip vim


## ENABLE START HTTPD
systemctl enable httpd
systemctl start httpd

exit



