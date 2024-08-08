# Project Documentation

## Table of contents

1. [Introduction](#Introduction)
2. [Project Overview](#Project-Overview)
   - [Objective](#Objective)
   - [Requirements](#Requirements)
3. [Deployment Instructions](#Deployment-Instructions)
4. [Code Files](#Code-files)
5. [Log Files](#Log-files)
6. [Screenshots](#Screenshots)
7. [Usage](#Usage)
8. [References](#References)

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
