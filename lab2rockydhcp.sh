nmcli con mod ens160 ipv4.method auto ipv6.method ignore ipv4.addresses "" ipv4.gateway "";

nmcli con up ens160;