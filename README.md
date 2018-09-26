# Auto Install Script for FreePBX / Asterisk / CentOS 7
Script to Automatically Install FreePBX / Asterisk on CentOS 7

Tested on:
* CentOS 7

Based on:
* https://wiki.freepbx.org/display/FOP/Installing+FreePBX+14+on+CentOS+7

### Software Versions installed:
* Asterisk 15.x
* FreePBX 14.x
* PHP 5.x (FreePBX requires this version)
* Apache 2.4.x (CentOS default)

The auto install script installs a slew of dependancies, the list is long. Check out the script source to see what is installed. 

## Installation

### Online installation

Run the following commands as root:

```
wget https://raw.githubusercontent.com/phillyit/centos-freepbx-autoinstall/master/install.sh
sh install.sh
```

After install is completed, it will direct you to your public server IP address, where you can create your admin credentials for FreePBX.


For more tutorials or guides visit us at [Philly IT](http://phillyit.com/)
