#!/bin/bash

echo
if [ ! "${USER}" = "root" ] ; then
   echo -e "Type $(tput setaf 1)sudo ./install.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

apt-get update
apt-get install -y postgresql libpq-dev 

# Install core-dev apps
core_apps=$(echo "build-essential libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev libssl-dev zlib1g-dev")
for a in $core_apps; do
     echo $(tput setaf 6)
     echo "Installing $a .... Please wait .... "$(tput sgr0)
     sudo apt-get -qq -y install $a
done

echo $(tput setaf 6)
echo "!!-- End of core-dev apps installation --!!"$(tput sgr0)

systemctl start postgresql
systemctl enable postgresql

echo $(tput setaf 6)
echo "Create database with following commands: (; at the end)"
echo $(tput setaf 3)
echo "sudo -u postgres psql"
echo "CREATE DATABASE netbox;"
echo "CREATE USER sysadmin WITH PASSWORD '67.Epping';"
echo "GRANT ALL PRIVILEGES ON DATABASE netbox TO sysadmin;"
echo $(tput setaf 6)
echo "Enter \q to quit"
echo "Login database again to confirm"
echo $(tput setaf 3)
echo "psql -U sysadmin -W -h localhost netbox"
echo $(tput sgr0)
