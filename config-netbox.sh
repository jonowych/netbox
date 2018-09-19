#!/bin/bash

echo
if [ ! "${USER}" = "root" ] ; then
   echo -e "Type $(tput setaf 1)sudo ./install.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

read -p "Enter password for netbox user "sydadmin": " -s password
echo -e "\nEnter password again: "
read -s user

if [ -z $password ] || [ -z $user ] || [ $password != $user ]
    then echo $(tput setaf 1)"!! Exit -- password entry error !!"$(tput sgr0)
    exit 1; fi

# set parameters
user="sydadmin"
intf=$(ifconfig | grep -m1 ^e | awk '{print $1}')
syshost=$(hostname)
sysip=$(ifconfig | grep $intf -A 1 | grep inet \
    | awk '{print $2}' | awk -F: '{print $2}')
    
# edit configuration files
cat <<EOF_nginx > /etc/nginx/sites-available/netbox
server {
    listen 80;
    server_name $sysip;
    client_max_body_size 25m;

    location /static/ {
        alias /opt/netbox/netbox/static/;
    }

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header X-Forwarded-Host $server_name;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        add_header P3P 'CP="ALL DSP COR PSAa PSDa OUR NOR ONL UNI COM NAV"';
    }
}
EOF_nginx

cd /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-available/default
rm -f default
ln -sf /etc/nginx/sites-available/netbox
service nginx restart

cat <<EOF_gunicorn > /opt/netbox/gunicorn_config.py
command = '/usr/local/bin/gunicorn'
pythonpath = '/opt/netbox/netbox'
bind = '127.0.0.1:8001'
workers = 3
user = '$user'
EOF_gunicorn

cat <<EOF_supervisor >/etc/supervisor/conf.d/netbox.conf
[program:netbox]
command = /usr/local/bin/gunicorn -c /opt/netbox/gunicorn_config.py netbox.wsgi
directory = /opt/netbox/netbox/
user = $user
EOF_supervisor

# Configure netbox
key=$(/opt/netbox/netbox/generate_secret_key.py)

# Escape special characters [/\&] to be used in sed
password=$(echo $password | sed -e 's-\/-\\\/-g; s-\\-\\\\-g; s-\&-\\\&-g')
key=$(echo $key | sed -e 's-\/-\\\/-g; s-\\-\\\\-g; s-\&-\\\&-g')

cp /opt/netbox/netbox/netbox/configuration.example.py /tmp/configuration.py
sed -e "s/^ALLOWED_HOSTS = \[\]$/ALLOWED_HOSTS = \['$syshost', '$sysip'\]/" \
    -e "s/'USER': '/'USER': '$user/" \
    -e "s/'USERNAME': '/'USERNAME': '$user/" \
    -e "s/'PASSWORD': '/'PASSWORD': '$password/" \
    -e "s/^SECRET_KEY = '/SECRET_KEY = '$key/" -i /tmp/configuration.py

echo $(tput setaf 3)
sudo mv -f /tmp/configuration.py /opt/netbox/netbox/netbox/
sed -e "/^#.*$/d" -e "/^$/d" /opt/netbox/netbox/netbox/configuration.py

echo $(tput setaf 6)
echo "Run Database migration with following commands:"
echo $(tput setaf 3)
echo "cd /opt/netbox/netbox/"
echo "python ./manage.py migrate"
echo "python ./manage.py createsuperuser"
echo "sudo python ./manage.py collectstatic --no-input"
echo "python ./manage.py loaddata initial_data"
echo "python ./manage.py runserver 0.0.0.0:8000 --insecure"
echo "service supervisor restart"
echo $(tput sgr0)
