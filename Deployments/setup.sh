#!/bin/bash

# setup script: Script to automate the deployment of a LAMP stack and clone a PHP application 

#-----------------------------------------------------------------------------------------------------
# Ensure the script is run with root privileges
#-----------------------------------------------------------------------------------------------------

if [[ "$(id -u)" -ne 0 ]]; then # if the identity of the user is not root, 
	sudo -E "$0" "$@"  # then, run the script with sudo priviledges preserving the environment variables
	exit
fi

#---------------------------------------------------------------------------------------------------------
# Log stdout to a file named script.log and any errors to a file named script_err.log
#---------------------------------------------------------------------------------------------------------

common_dir="/vagrant"
log_stdout="$common_dir/script.log"
log_error="$common_dir/script_err.log"
exec > >(tee -a $log_stdout) 2>$log_error

#-------------------------------------------------------------------------------------------------------
# commence logging of output
#-------------------------------------------------------------------------------------------------------
echo "---------------------------loggging output started at $(date)-------------------------------------"

#---------------------------------------------------------------------------------------------------------
# Install relevant repositories to Advanced Package Tool Manager
#---------------------------------------------------------------------------------------------------------
echo "------------------------Adding Relevant Repositories to APT manager--------------------------------"
apt-get install -y software-properties-common
apt-get install -y python-apt
add-apt-repository -y ppa:ondrej/php


#--------------------------------------------------------------------------------------------------------
# Update package list and upgrade installed packages
#--------------------------------------------------------------------------------------------------------
echo "------------Updating package list and upgrading installed packages--------------------------------"
apt-get update -y && apt-get upgrade -y

#---------------------------------------------------------------------------------------------------------
# Install and enable Apache webserver
#-----------------------------------------------------------------------------------------------------------
echo "------------Installing and enabling apache webserver-------------------------------------------------"
apt-get install -y apache2
systemctl start apache2
systemctl enable apache2

#------------------------------------------------------------------------------------------------------------
# A secure mysql root passwd is generated utilizing current unix timestamp and Secure Hash Algorithm(SHA-256)
# Install MYSQL in a non interactive mode
# Disable remote root login
# Drop test Database if it exists
#----------------------------------------------------------------------------------------------------------
echo "----------Generating a random secure myql root password---------------------------------------"
mysql_root_password="$(date +%s | sha256sum | base64 | head -c 20)"
echo "-----------mysql root passwd: '$mysql_root_password'-------------------------------------------------"

echo "-----------------Installing MySQL Server in a non interactive mode--------------------------------"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysql_root_password"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysql_root_password"
apt-get install -y mysql-server

echo "-------Disabling mysql remote root login"------------------------------------------------------------
sed -i "s/.*bind-address.*/bind-address = 127.0.0.1/" /etc/mysql/mysql.conf.d/mysqld.cnf

echo "-----------------------Dropping the test database if it exists--------------------------------"
mysql -uroot -p"$mysql_root_password" -e "DROP DATABASE IF EXISTS test;" || true

systemctl restart mysql

#-----------------------------------------------------------------------------------------------------------
# Install PHP8.2 and its dependencies (Laravel requires PHP 8.1 and above to run
# Configure PHP cgi.fix path info
# Restart Apache2
#-----------------------------------------------------------------------------------------------------------
echo "-----------------Installing PHP and its dependencies--------------------------------------------------"
apt-get install -y php8.2 libapache2-mod-php8.2 php8.2-common php8.2-mysql php8.2-gmp php8.2-curl php8.2-intl php8.2-mbstring php8.2-xmlrpc php8.2-gd php8.2-xml php8.2-cli php8.2-zip php8.2-tokenizer php8.2-bcmath php8.2-soap php8.2-imap unzip zip || exit

echo "----------------configuring php cgi.fix.pathinfo------------------------------------------------"
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.2/apache2/php.ini

echo "-----------------restarting apache2 webserver----------------------------------------------------"
systemctl restart apache2

#----------------------------------------------------------------------------------------------------------
# Install Composer
#----------------------------------------------------------------------------------------------------------
echo "------------Downloading composer installer script and executing with PHP---------------------------"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#----------------------------------------------------------------------------------------------------------
# Laravel Application Setup
# Install git if it is not present
#----------------------------------------------------------------------------------------------------------
echo "--------------------------------confirming the status of git------------------------------------------------------"
if [[ "$(git --version | echo $?)" -ne 0 ]]; then
        echo "-------git not installed: installing git--------------"
	apt-get install git -y
else
	echo "------------git already installed: updating git-----------"
	apt-get update -y && apt-get install --only-upgrade git -y
fi

echo "------navigating to web root directory & clone laravel-------------------------------"
laravel_repository="https://github.com/laravel/laravel.git"

cd /var/www/html || exit 
git clone $laravel_repository

echo "-----------navigating to laravel repository---------------------------------------------------"
cd laravel || exit

echo "------------installing laravel dependencies composer dependecy manager------------------------"
composer install --no-interaction --optimize-autoloader --no-dev
composer update --no-interaction --optimize-autoloader --no-dev

echo "-------------------------------obtaining the webserver username-------------------------------"
webserver_username="$(ps aux | grep "apache" | cut -d ' ' -f 1 | grep -v "root" | head -n 1)"
echo "---------------------------------setting laravel permissions--------------------------------------"
chown -R $webserver_username:$webserver_username /var/www/html/laravel
chmod -R 775 /var/www/html/laravel
chmod -R 775 /var/www/html/laravel/storage
chmod -R 775 /var/www/html/laravel/bootstrap/cache

echo "------------building an .env file for environment specific configurations from .env.example-----"
cp .env.example .env

echo "---------------Generating Application key within the .env file---------------------------------"
php artisan key:generate

#-----------------------------------------------------------------------------------------------------
# Mysql database configuration-----------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------
echo "-----------------------configuring Database---------------------------------------------------"
# define variables
db="laravel"
username="root"

mysql -u $username -p"$mysql_root_password" <<__EOL__
CREATE DATABASE $db;
GRANT ALL PRIVILEGES ON $db.* TO '$username'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
__EOL__

# The .env file is updated
sed -i "s/^.*DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
sed -i "s/^.*DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/^.*DB_DATABASE=.*/DB_PASSWORD='$db'/" .env
sed -i "s/^.*DB_USERNAME=.*/DB_USERNAME='$username'/" .env
sed -i "s/^.*DB_PASSWORD=.*/DB_PASSWORD='$mysql_root_password'/" .env

echo "-----------------Restarting mysql--------------------------------------------------------------"
systemctl restart mysql

#---------------------------------------------------------------------------------------------------------
# Cache the configuration values & Run database migration
#---------------------------------------------------------------------------------------------------------
echo "-------------------------------------caching config values--------------------------------------"
php artisan config:cache

echo "----------------------------- Running the database migrations------------------------------------"
php artisan migrate --force

# Restart Apache web server
echo "----------------------------Apache web server-------------------------------"
systemctl restart apache2


#--------------------------------------------------------------------------------------------------------
# Web server configuration
#--------------------------------------------------------------------------------------------------------
# define variables and obtain server ip address
admin_email="22010992@hope.ac.uk"

echo "---------------------------obtaining server ip----------------------------------------------------"

server_ip=""
# Checking if the interface eth1 exists
if ip addr show eth1 &>/dev/null; then
	server_ip="$(ip addr show eth1 | awk '/inet /{print $2}' | cut -d '/' -f 1)"
else
	# If eth1 doesn't exist, check for enp0s8
	server_ip="$(ip addr show enp0s8 | awk '/inet /{print $2}' | cut -d '/' -f 1)"
fi

echo "------Server Ip address is: $server_ip----------------------------------------"

# Configure Apache web server

echo "--------------------generating laravel Apache configuration file--------------"
cat > /etc/apache2/sites-available/laravel.conf <<-__EOL__
<VirtualHost *:80>
    ServerAdmin $admin_email
    ServerName $server_ip
    DocumentRoot /var/www/html/laravel/public

    <Directory /var/www/html/laravel>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
__EOL__


echo "----------------------diabling default apache2 site config-----------------------------"
a2dissite 000-default.conf

echo "---------------------Enabling Laravel site config file --------------------------------"
a2enmod rewrite
a2ensite laravel.conf

echo "--------------------- Enabling the PHP module in Apache --------------------------------"
a2enmod php8.2

echo "------------------------- Restarting Apache web server ---------------------------------"
systemctl restart apache2

#----------------------------------------------------------------------------------------------
# Enabling Firewall
# Add Firewall rules for Openssh(Port 22), port 80(HTTP), port 443(HTTPS), port 3306(MYSQL)
# over transmission control protocol(TCP)
#---------------------------------------------------------------------------------------------
echo "-------------------checking if UFW is installed----------------------------------------"
if ! dpkg --get-selections | grep -q "ufw"; then
       	echo "ufw not installed"
        echo "Installing ufw"
     	apt-get install -y ufw
else
	echo "ufw is installed"
fi

echo "--------------------------enabling ufw-------------------------------------------------"
ufw --force enable


echo "------------------------Adding Firewall rules------------------------------------------"
ufw allow openssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3306/tcp

echo "--------------------------END OF SCRIPT LOGGING-----------------------------------------"
