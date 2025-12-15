#!/bin/bash

hostnamectl set-hostname dorado.jht3250.com;
hostnamectl;

nmcli connection modify ens160 \
    ipv4.addresses 192.168.10.11/24 \
    ipv4.gateway 192.168.10.1 \
    ipv4.dns 8.8.8.8;

nmcli connection up ens160;
date; hostname; ip a;