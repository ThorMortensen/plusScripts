# Quality of Life Scripts

This is a collection of scripts and settings frequently used on Linux. This repo is a hub for syncing settings and scripts between machines.

### Installation
```
git clone git@github.com:ThorMortensen/plusScripts.git && cd plusScripts && ./run_install
```
Follow instructions..

### WiFi drivers 

Use this: https://github.com/lwfinger/rtw89.git


### New Network (not ifconfig)


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
      - <added static address>/16
      nameservers:
        addresses:
        -  <Remember nameserver !!>
    <next addapter>:
      dhcp4: yes
      addresses:
      - <added static address>/16
      nameservers:
        addresses:
        -  <Remember nameserver !!>
  wifis:
    wlp9s0:
      dhcp4: yes
      dhcp6: yes
      addresses:
      - <added static address>/16
      nameservers:
        addresses:
        -  <Remember nameserver !!>
      access-points:
        "Rovsing":
          password: "xxxxxxxxxx"
```
(Correct indentation is important. Use only spaces)
Run `sudo netplan apply` to apply the netplan. It may be useful to restart if this is the first time.


