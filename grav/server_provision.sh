#!/bin/bash


## EPEL-RELEASE
yum -y install epel-release

## WEBTATIC
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y update
yum clean all


## YUM INSTALL UTILITIES
yum -y install httpd php72w php72w-curl php72w-openssl php72w-zip php72w-pecl-apcu php72w-gd  php72w-xml php72w-mbstring php72w-opcache wget unzip vim ed


## ENABLE START HTTPD
systemctl enable httpd
systemctl start httpd


## DOWNLOAD THE GRAV SKELETON
wget  https://getgrav.org/download/skeletons/learn2-with-git-sync-site/1.2.0/grav-skeleton-learn2-versioned-docs-with-git-sync-site-beta.zip -P /opt ; cd /opt


## TRANSFER FILES TO /var/www/html
unzip grav-skeleton-learn2-versioned-docs-with-git-sync-site-beta.zip
mv /opt/grav-skeleton-learn2-versioned-docs-with-git-sync-site-beta/{.[!.],}* /var/www/html

## DISABLE SELINUX
sed -i 's/enforcing/disabled/g' /etc/selinux/config

## SET PERMISSIONS ON WEB FOLDER
chown -R apache:apache /var/www/html

## UPDATE HTTPD.CONF (1)
sed -i '151s/None/All/' /etc/httpd/conf/httpd.conf

## UPDATE HTTPD.CONF (2)
ed /etc/httpd/conf/httpd.conf << END
58i
LoadModule php7_module  modules/libphp7.so
AddType x-httpd-php .php
AddHandler php7-script .php
.
w
q
END



## RESTART MACHINE
systemctl reboot

exit



