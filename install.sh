#!/bin/bash
echo 'Running Asterisk / FreePBX Install'
START_TIME=$SECONDS

###
echo 'Checking SELINUX'
	if sestatus | grep 'SELinux status' | grep enabled ; then
		echo -e '\tSELinux is enabled... disabling!'
		  sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config 
		  sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/sysconfig/selinux
		  echo -e '\t\tSELinux was disabled, you must reboot and rerun script!'
		  exit 0
	else
		echo -e '\tSELinux is disabled, proceeding with install.'
	fi

###
echo 'Running Updates'
yum -y update
echo -e '\tUpdates complete.'

###
echo 'Installing Development Tools'
yum -y groupinstall core base "Development Tools" 
echo -e '\tDevelopment tools installed.'

###
echo 'Adding Asterisk User'
adduser asterisk -m -c "Asterisk User"
echo -e '\tAsterisk User added.'

###
echo 'Opening Port 80 on Firewall'
firewall-cmd --zone=public --add-port=80/tcp --permanent 
firewall-cmd --reload 
echo -e '\tPort 80 opened.'

###
echo 'Installing Dependencies, this will take a while'
yum -y install lynx tftp-server unixODBC mysql-connector-odbc mariadb-server mariadb \
  httpd ncurses-devel sendmail sendmail-cf sox newt-devel libxml2-devel libtiff-devel \
  audiofile-devel gtk2-devel subversion kernel-devel git crontabs cronie \
  cronie-anacron wget vim uuid-devel sqlite-devel net-tools gnutls-devel python-devel texinfo \
  libuuid-devel 
echo -e '\tDependencies installed.'

###
echo 'Installing PHP'
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm 
yum remove php* 
yum install -y php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear php56w-process \
  php56w-xml php56w-opcache php56w-ldap php56w-intl php56w-soap 
echo -e '\tPHP Installed.'

###
echo 'Installing Nodejs'
curl -sL https://rpm.nodesource.com/setup_8.x | bash - 
yum install -y nodejs >> install.log 2>&1
echo -e '\tNodejs installed.'

###
echo 'Starting MariaDB'
systemctl start mariadb 
echo -e '\tMariaDB started.'

###
echo 'Securing MariaDB'
mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')" 
mysql -u root -e "DELETE FROM mysql.user WHERE User=''" 
mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'" 
mysql -u root -e "FLUSH PRIVILEGES" 
echo -e '\tMariaDB secured.'

###
echo 'Starting Apache'
systemctl start httpd
echo -e '\tApache started.'

###
echo 'Installing Pear Requirements'
pear install Console_Getopt 
echo -e '\tPear reqs installed.'

###
echo 'Downloading Jansson and Asterisk'
cd /usr/src 
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-15-current.tar.gz
wget -O jansson.tar.gz https://github.com/akheron/jansson/archive/v2.10.tar.gz
echo -e '\tDownload complete.'

###
echo 'Compiling and Installing Jansson'
cd /usr/src
tar vxfz jansson.tar.gz
rm -f jansson.tar.gz
cd jansson-*
autoreconf -i
./configure --libdir=/usr/lib64
make
make install
echo -e '\tJansson install complete.'

###
echo 'Compiling and Installing Asterisk, this will take a while'
cd /usr/src
tar xvfz asterisk-15-current.tar.gz
rm -f asterisk-15-current.tar.gz
cd asterisk-*
contrib/scripts/install_prereq install
./configure --with-pjproject-bundled
make menuselect
make
make install
make config
ldconfig
echo -e '\tAsterisk install complete.'

###
echo 'Setting Asterisk Permissions'
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www/
echo -e '\tAsterisk permissions set.'

###
echo 'Updating Apache Config'
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php.ini
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
systemctl restart httpd.service
echo -e '\tApache config updated.'

###
echo 'Installing FreePBX'
cd /usr/src
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-14.0-latest.tgz
tar xfz freepbx-14.0-latest.tgz
rm -f freepbx-14.0-latest.tgz
cd freepbx
./start_asterisk start
./install -n
echo -e '\tFreePBX installed.'
 
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "Run time: $(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec"    

var=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
echo "*** All done, please visit http://$var/ to configure your FreePBX server! ***"
