#!/bin/bash
# LAB 2 RUN AS ROOT ON ROCKY

DOMAIN="jht3250.com"
ADMIN_USER="jtreon"

dnf update -y

dnf install -y realmd sssd oddjob oddjob-mkhomedir adcli samba-common-tools

systemctl enable --now realmd

realm join --user=$ADMIN_USER $DOMAIN

realm list