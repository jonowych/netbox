#!/bin/bash

echo
if [ ! "${USER}" = "root" ] ; then
   echo -e "Type $(tput setaf 1)sudo ./install.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

# Prepare for Install... on User's directory
#

sudo apt-get update 

core_apps=$(echo "postgresql libpq-dev")

# Install core apps
#

for a in $core_apps; do
     echo -e $(tput setaf 6)"Installing $a .... Please wait ...." $(tput sgr0)
     sudo apt-get -qq -y install $a
     echo $a has been installed
     echo
done
echo && echo -e $(tput setaf 6)"!-- End of core apps installation --"$(tput sgr0)

systemctl start postgresql
systemctl enable postgresql

echo $(tput setaf 6)
echo "Create database with following commands: (; at the end)"
echo "sudo -u postgres psql"
echo "CREATE DATABASE netbox;"
echo "CREATE USER sysadmin WITH PASSWORD '\$password';"
echo "GRANT ALL PRIVILEGES ON DATABASE netbox TO sysadmin;"
echo "Enter \q to quit"
echo "Login database again to confirm"
echo "psql -U sysadmin -W -h localhost netbox"
echo $(tput sgr0)
