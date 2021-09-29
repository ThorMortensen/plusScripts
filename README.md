# Quality of Life Scripts

This is a collection of scripts and settings frequently used on Linux. This repo is a hub for syncing settings and scripts between machines.

### Installation
```
git clone git@github.com:ThorMortensen/plusScripts.git && cd plusScripts && ./run_install
```
Follow instructions..



### New Network (not ifconfig)

Set the network manager to manage the wired networks in this file `sudo nano /etc/NetworkManager/NetworkManager.conf`

```
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=true  # <-- Make sure this is set to true

[device]
wifi.scan-rand-mac-address=no

```

Restart the network manager: `sudo service network-manager restart`

The network should be shown as managed in the system tray now.


Use netplan to manage the network. Open the netplan file located here:

`sudo nano /etc/netplan/` the file looks something like this: `01-network-manager-all.yaml`.

example: `sudo nano /etc/netplan/01-network-manager-all.yaml`

Add the addresses you need to the yaml file:

```
# Let NetworkManager manage all devices on this system
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s31f6:
      dhcp4: yes
      addresses:
      - 192.168.50.232/24
      - 192.168.0.232/24
      gateway4: 192.168.255.1
#      netmask: 255.255.0.0
```
(Correct indentation is important. Use only spaces)
Run `sudo netplan apply` to apply the netplan. It may be useful to restart if this is the first time.
