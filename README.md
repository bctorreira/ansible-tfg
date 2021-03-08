# onm-ansible

Ansible dedicated repository. 
Clone this repo and move its contents to `/etc/ansible`, overwriting any files if needed.

 ## Modified config parameters
 ```
 [defaults]

 # use the 'local' file in the working directory as inventory
 inventory = ./local
 
 # install and search for roles in the 'roles_galaxy' directory under the working directory
 roles_path = ./roles_galaxy

 # enable logging and log into /var/log/ansible.log
 log_path = /var/log/ansible.log

 # always use this private key for ssh authentication
 private_key_file = ./keys/ansible_key

 # set the path to the Vault password file
 vault_password_file = ./VAULT_PASSWORD_FILE

 [privilege_escalation]

 # always allow privilege escalation through sudo
 become = True

 # always ask for sudo password
 become_ask_pass = True
 ```
