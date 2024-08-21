
# Laravel_demo_app - LAMP Stack Deployment

## Table of Contents

1. [Introduction](#introduction)
2. [Project Overview](#project-overview)
   - [Objective](#objective)
   - [Requirements](#requirements)
3. [Deployment Instructions](#deployment-instructions)
4. [Code Files](#code-files)
   - [Vagrantfile](#vagrantfile)
   - [setup.sh](#setupsh)
   - [ansible.cfg](#ansiblecfg)
   - [inventory.ini](#inventoryini)
   - [playbook.yaml](#playbookyaml)
5. [Log Files](#log-files)
   - [script.log](#scriptlog)
   - [script_err.log](#script_errlog)
   - [uptime.log](#uptimelog)
6. [Screenshots](#screenshots)
   - [ControlNode and ManagedNode1 in VirtualBox](#controlnode-and-managednode1-in-virtualbox)
   - [Laravel App on ControlNode](#laravel-app-on-controlnode)
   - [Playbook Execution](#playbook-execution)
   - [Laravel App on ManagedNode1](#laravel-app-on-managednode1)
7. [Usage](#usage)
8. [Contributions](#contributions)
9. [References](#references)

## Introduction

Welcome to the Laravel_demo_app project! This project automates the provisioning and deployment of a LAMP (Linux, Apache, MySQL, PHP) stack using Vagrant, a Bash script, and Ansible. The Laravel application is sourced from the official Laravel GitHub repository, and this project streamlines the process of setting up a web server environment.

## Project Overview

### Objective

The primary goal of this project is to automate the provisioning of two Ubuntu-based servers using Vagrant. The automation includes:

- Creating a Bash script for deploying the LAMP stack on the ControlNode.
- Cloning a Laravel PHP application from GitHub.
- Installing necessary packages.
- Configuring Apache and MySQL.
- Ensuring the Bash script is reusable and readable.

The Ansible playbook is used to:

- Execute the Bash script on the ManagedNode.
- Set up a cron job to check server uptime daily at 1am.

### Requirements

- Vagrant
- VirtualBox
- Ansible
- Ubuntu 20.04 (focal64) Base Box

## Deployment Instructions

### Configuring Multi-VM Servers with Vagrant

Two Ubuntu servers, ControlNode and ManagedNode, are provisioned using the `Vagrantfile`. The `Vagrantfile` includes configurations for the base box, network settings, and provisioning requirements.

### Automating Deployment with Bash Script

The `setup.sh` script automates the deployment of the LAMP stack and Laravel application on the ControlNode.

### Ansible Playbook Execution

The Ansible playbook `playbook.yaml` automates the deployment of the `setup.sh` script on the ManagedNode and sets up a cron job.

## Code Files

### Vagrantfile

Defines the configuration for the two Ubuntu-based virtual machines, ControlNode, and ManagedNode.

### setup.sh

A script that automates the deployment of the LAMP stack, installation of necessary packages, configuration of Apache, and deployment of the Laravel application.

### ansible.cfg

Ansible configuration file that specifies settings like inventory location and SSH key path.

### inventory.ini

Ansible inventory file that lists the ControlNode and ManagedNode along with their IP addresses and connection details.

### playbook.yaml

Ansible playbook that automates the execution of the `setup.sh` script on the ManagedNode and sets up a cron job for server uptime monitoring.

## Log Files

### script.log

Logs the output of the `setup.sh` script.

### script_err.log

Logs any errors encountered during the execution of the `setup.sh` script.

### uptime.log

Logs the server uptime checked daily by the cron job.

## Screenshots

### ControlNode and ManagedNode1 in VirtualBox

Screenshot of both the ControlNode and ManagedNode1 running in VirtualBox.

### Laravel App on ControlNode

Screenshot of the Laravel application running on the ControlNode.

### Playbook Execution

Screenshot of the Ansible playbook execution process.

### Laravel App on ManagedNode1

Screenshot of the Laravel application running on the ManagedNode1.

## Usage

1. Clone the project repository from GitHub.
2. Configure the Vagrantfile for the desired environment.
3. Run `vagrant up` to start the virtual machines with the specified configuration.
4. SSH into the ControlNode using `vagrant ssh ControlNode`.
5. Access the Laravel application on the ControlNode using its IP address.
6. Copy the [Deployments](https://github.com/ikennaozurumba/Laravel_demo_app/tree/main/Deployments) directory to the users home directory. 
7. Run `ansible-playbook playbook.yaml` on the ControlNode to deploy the LAMP stack on the ManagedNode.

## Contributions

Contributions are welcome! Please fork this repository, make your changes, and submit a pull request.

Documentation
For detailed instructions, refer to the [Project Documentation](https://github.com/ikennaozurumba/Laravel_demo_app/blob/main/Documentation.md).


## References

- [Laravel GitHub Repository](https://github.com/laravel/laravel)
- [Ansible Documentation](https://docs.ansible.com/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [codewithsusan](https://codewithsusan.com/notes/deploy-laravel-on-apache)
- [Hamed-Ayodeji/Star-fish-a-laravel-project](https://github.com/Hamed-Ayodeji/Star-fish-a-laravel-project.git)


## Author
Ikenna Ozurumba
