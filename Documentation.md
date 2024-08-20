# Project Documentation

## Table of contents

1. [Introduction](#Introduction)
2. [Project Overview](#Project-Overview)
   - [Objective](#Objective)
   - [Requirements](#Requirements)
3. [Deployment Instructions](#Deployment-Instructions)
4. [Code Files](#Code-files)
   - [Vagrantfile](#Vagrantfile)
   - [setup.sh](#setup.sh)
   - [ansible.cfg](#ansible.cfg)
   - [inventory.ini](#inventory.ini)
   - [playbook.yaml](#playbook.yaml)
5. [Log Files](#Log-files)
   - [script.log](#script.log)
   - [script_err.log](#script_err.log)
   - [uptime.log](#uptime.log)
7. [Screenshots](#Screenshots)
   - [Screenshot of ControlNode and ManagedNode1 on VB](#Screenshot_of_ControlNode_and_ManagedNode1_on_VB)
   - [Laravel app deployed on ControlNode](#Laravel_app_deployed_on_ControlNode)
   - [Playbook Execution](#Playbook_Execution)
   - [Laravel app deployed on ManagedNode1](#Laravel_app_deployed_on_ManagedNode1)
9. [Usage](#Usage)
10. [Contributions](#Contributions)
11. [References](#References)

## [Introduction](Introduction)

Welcome to the documentation for Star Fish Laravel project (Deploy LAMP stack). This documentation provides a comprehensive guide for automating the provisioning and deployment of a LAMP (Linux, Apache, Mysql, and PHP) stack using vagrant, a bash script, Ansible and a PHP application (Laravel). The project aims to streammline to the process of setting up a web server environment for hosting PHP application, in this case a Laravel application cloned from the official Laravel repository [Github Repository for Laravel](https://github.com/laravel/laravel)

## [Project Overview](Project-Overview)

### [Objective](Objective)

The primary objective of this project is to automate the provisioning of two ubuntu-based servers using vagrant . The automation involves the following steps:
  1. Create a bash script to automate the deployment of the LAMP stack on the Control node.
  2. Clone a PHP application from Github.
  3. Install a the necessary packages
  4. Configure apache webserver and Mysql
  5. Ensure bashscript is reusable and readble

In addition to the bash script, an ansible playbook is used to:
  1. Execute the bash script on the slave node  
  2. Create a cron job to check the server's uptime everyday at midnight

It is also important to verify that the PHP application is accessible through the VM's IP address and screenshot taken as evidence.

## [Deployment Instructions](Deployment-Instructions)

In this section, the steps to deploy the LAMP stack using vagrant, the bash script and the ansible playbook will be covered.

### Configuring multi-VM Servers with Vagrant

Two ubuntu servers (ControlNode and ManagedNode) are provisioned by configuring the `Vagrantfile`. The file defines the configuration for the base box, , the network settings, and provisioning requirements.

  1. **Vagrantfile Confuguration**: `ubuntu/focal64` is selected as the base box for both VM's, a private network with a static IP address is configured in the network settings for both VMs and `Virtualbox` is configured as the VM provider for both machines.

```ruby
# -*- mode: ruby -*-
# vi set ft=ruby :

# Configuration file for two ubuntu based VM names ControlNode and ManagedNode

Vagrant.configure("2") do |config|

  # Define a common base box for all VMs
  config.vm.box = "ubuntu/focal64"

  # Define the ControlNode
  config.vm.define "ControlNode" do |ControlNode|
    # ControlNode server settings
    # .....

  end
 
  # Define ManagedNode
    config.vm.define "ManagedNode" do |ManagedNode|
    # ManagedNode server settings
    # ....

  end
  
end
```

2. **Provisioning Script**: SSH configurations are provisioned in the vagrantfile to enable secure connectivity between the ControlNode and the ManagedNode.

The configuration script can be found in [Vagrantfile](#Vagrantfile)

### Automating Deployment with Bash Script

The `deploy.sh` [script](#deploy.sh) automates the deployment of the LAMP stack. It performs the following task:

  1. Add important repositories to the APT package manager.
  2. Updates and upgrades installed packages
  3. Installs Apache, MYSQL, PHP, and other necessary packages
  4. Configures Apache for Laravel application
  5. Installs Composer and Sets permissions.
  6. Clones the Laravel application from Github and configures it.
  7. Setup the MYSQL database and update the .env` file.
  8. Caches configuration values and runs database migrations.
  9. Sets firewall rules to enable necessary ports

### Ansible Playbook Execution

Th ansible playbook `playbook.yaml` automates the execution of `deploy.sh` [script](#deploy.sh) on the `ManagedNode` server and sets up a cron job to check the server uptime.
  1. **Copying Deployment script**: The playbook copies the `deploy.sh` script to the `ManagedNode` server.
  2. **Executing Deployment script**: The script gets executed and logs the output
  3. **Permission and Cron job**: The playbook ensures correct permissions for directories and creates a cron job to check the server uptime

The Ansible playbook and it's configurations are documented in:
* [Playbook](#playbook.yaml)
* [Ansible Inventory](#inventory.ini)
* [Ansible Configuration file](#ansible.cfg)


## [Code Files](Code-files)


### [Vagrantfile](Vagrantfile): Configuration for vagrant file

```ruby
# -*- mode: ruby -*-
# vi set ft=ruby :

# Configuration for two Ubuntu Servers (ControlNode and ManagedNode1)

Vagrant.configure("2") do |config|

  # Define a common base box for both VMs
  config.vm.box = "ubuntu/focal64"

  # Define the ControlNode
  config.vm.define "ControlNode" do |control|
    control.vm.hostname = "ControlNode"
    control.vm.network "private_network", ip: "192.168.33.12"

    # VM provider configuration
    control.vm.provider "virtualbox" do |v|
      v.name = "ControlNode"
      v.memory = 1024
      v.cpus = 1
    end

    # Provisioning script for ControlNode
    control.vm.provision "shell", inline: <<-SHELL
      # switch user to vagrant
      # Generate id_rsa key for connection with the ManagedNode
      su - vagrant -c '
      if [[ ! -f /home/vagrant/.ssh/id_rsa ]]; then
        ssh-keygen -t rsa -b 2048 -f /home/vagrant/.ssh/id_rsa -q -N ""
      fi
      cp /home/vagrant/.ssh/id_rsa.pub /vagrant/id_rsa.pub
      '
      sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' "/etc/ssh/sshd_config"
      sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "/etc/ssh/sshd_config"
      sudo systemctl restart ssh || sudo service ssh restart
    SHELL
    control.vm.provision "shell", path: "./Deployments/setup.sh"
    control.vm.provision "shell", inline: <<-SHELL
        # update apt && install ansible
        sudo apt-get update -y
        sudo apt-get install ansible -y
    SHELL
  end


    # Define ManagedNode
  config.vm.define "ManagedNode1" do |node1|
     node1.vm.hostname = "ManagedNode1"
     node1.vm.network "private_network", ip: "192.168.33.13"

     node1.vm.provider "virtualbox" do |v|
       v.name = "ManagedNode1"
       v.memory = 1024
       v.cpus = 1
     end

     # Provisioning script
     node1.vm.provision "shell", inline: <<-SHELL
       echo "Hello, welcome to the managed node1 virtual machine"

       if [[ ! -f /vagrant/.ssh/id_rsa ]]; then
         echo -e "\n\n" >> /home/vagrant/.ssh/authorized_keys
         cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
         chmod 600 /home/vagrant/.ssh/authorized_keys
         chown -R vagrant:vagrant /home/vagrant/.ssh
       fi

       sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' "/etc/ssh/sshd_config"
       sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "/etc/ssh/sshd_config"
       sudo systemctl restart ssh || sudo service ssh restart
     SHELL
  end

end
                                                                                                                                             1,1           Top
```


### [setup.sh](setup.sh): Script to automate the deployment of a LAMP stack and clone a PHP application
     
```bash
#!/bin/bash


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

```


### [ansible.cfg](ansible.cfg): Ansible Configuration file

```ini
[defaults]
inventory = inventory.ini
private_key_file = ~/.ssh/id_rsa
host_key_checking = False

```

### [inventory.ini](inventory.ini): Ansible Inventory file:

```ini
ControlNode ansible_host=192.168.33.12 ansible_user=vagrant ansible_connection=ssh
ManagedNode1 ansible_host=192.168.33.13 ansible_user=vagrant ansible_connection=ssh
```

### [playbook.yaml](playbook.yaml): Ansible playbook file automating the deployment of setup.sh script on the ManagedNode

```yaml
# Playbook file: Automates the deployment of setup.sh on Manages Nodes

- name: Execute Deployment Script
  hosts: ManagedNode1
  become: yes

  tasks:
    - name: Copy Deployment Script
      copy:
        src: ./setup.sh
        dest: /tmp/setup.sh
        mode: 0775

    - name: Execute Deployment Script
      shell: /tmp/setup.sh >> /vagrant/ansible.log 2> ansible_err.log

    - name: Set permission for /vagrant directory
      file:
        path: /vagrant
        state: directory
        mode: 0755
        owner: vagrant
        group: vagrant

    - name: Create uptime.log and set permissions for uptime.log file
      file:
        path: /vagrant/uptime.log
        state: touch
        mode: 0644

    - name: Create a cron job to check the server's uptime every 1 am
      cron:
        name: "Log server uptime"
        minute: "0"
        hour: "1"
        job: "uptime >> /vagrant/uptime.log"
        user: vagrant

```


## [Screenshots](Screenshots)

### [Screenshot of ControlNode and ManagedNode1 on VB](Screenshot_of_ControlNode_and_ManagedNode1_on_VB)

### [Laravel app deployed on ControlNode](Laravel_app_deployed_on_ControlNode)

### [Playbook Execution](Playbook_Execution)

### [Laravel app deployed on ManagedNode1](Laravel_app_deployed_on_ManagedNode1)


## [Usage](Usage)

The following steps detail how to use to use the project to deploy a LAMP stack and maintain the server environment.

1. Clone this projects's github repository: []()
2. Configure and provision the Vagrantfile to the desired ControlNode and ManagedNode server environments.
3. Run `vagrant up` in the projects directory to bring up the virtual machines with the customized configurations.
4. The ControlNode server will be setup with a LAMP stack as specified in the `setup.sh` script. Details of the provisioning as well as posible errors can be found in the script.log and script_err.log files, respectively.
5. Once the VMs have been povisioned, run `vagrant ssh ControlNode` to ssh into the controlNode.
6. Using the ControlNode IP address or domain name, access the Laravel application on a browser.
7. On the ControlNode shell, run `ansible-playbook playbook.yaml` to deploy the LAMP stack on the ManagedNode.
   - Ansible will copy the `script.sh` script into the ManagedNode and execute the script to deploy the LAMP stack on the ManagedNode server, which can be accessed using the server IP address or domain name.
   - Standard output as well as any errors from the deployment on the ManagedNode can be found in the ansible.log and ansible_err.log file, respectively.
   - Ansible will also setup a CRON job to check server uptime. The details of the CRON job can be found in the uptime.log file.

## [Contributions](Contributions)

To contribute to this project, follow these steps:

1. Fork the project's GitHub repository []().

2. Create a branch for the feature or bug fix.

3. Make the changes and commit them to the branch.

4. Submit a pull request to the main repository for review and integration.

   ## [References](References)

- [GitHub Repository for Vagrant](https://github.com/hashicorp/vagrant)
- [GitHub Repository for Laravel](https://github.com/laravel/laravel)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [Laravel PHP Framework](https://laravel.com)
- [codewithsusan](https://codewithsusan.com/notes/deploy-laravel-on-apache)
- [Hamed-Ayodeji/Star-fish-a-laravel-project](https://github.com/Hamed-Ayodeji/Star-fish-a-laravel-project.git)
     


                                                                                                                                             170,0-1       65% 
                                                                                                                                             65,0-1        15% 
