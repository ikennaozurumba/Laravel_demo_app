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
      echo "Hello, welcome to the ManagedNode1 virtual machine"
      
      # Ensure .ssh directory exists
      mkdir -p /home/vagrant/.ssh
      chmod 700 /home/vagrant/.ssh
      chown -R vagrant:vagrant /home/vagrant/.ssh

      # Add ControlNode's public key to authorized_keys if not already added
      if ! grep -q "$(cat /vagrant/id_rsa.pub)" /home/vagrant/.ssh/authorized_keys 2>/dev/null; then
        cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
        chmod 600 /home/vagrant/.ssh/authorized_keys
        chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
      fi
        
      sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' "/etc/ssh/sshd_config"
      sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "/etc/ssh/sshd_config"
      sudo systemctl restart ssh || sudo service ssh restart
    SHELL
  end
  
end
