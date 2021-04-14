# onm-ansible

Ansible dedicated repository.

Clone this repo and move its contents to `/etc/ansible`, overwriting any files if needed.

## Modified ansible configuration parameters
```
[defaults]

# use the 'local' file in the working directory as inventory
inventory = ./local

# use 'debug' callback to improve output readability
stdout_callback = debug

# default user to use for playbooks if user is not specified
remote_user = ansible

# install and search for roles in the 'roles_galaxy' directory under the working directory
roles_path = ./roles_galaxy

# enable logging and log into /var/log/ansible.log
log_path = /var/log/ansible.log

# use this private key for ssh authentication
private_key_file = ./keys/ansible_key

# set the path to the Vault password file
vault_password_file = ./VAULT_PASSWORD_FILE


[privilege_escalation]

# always allow privilege escalation through sudo
become = True

# always ask for sudo password
become_ask_pass = True

[ssh_connection]

# ssh arguments to use, defaul values + `-o StrictHostKeyChecking=no` to skip host authenticity confirmation
ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
```

## Inventory organization
Ansible works against multiple managed nodes or “hosts” in your infrastructure at the same time, using a list or group of lists known as inventory. These “hosts” may be **hostnames** or **ip addresses**.

There are two default groups: `all` and `ungrouped`. The `all` group contains every host. The `ungrouped` group contains all hosts that don’t have another group aside from `all`. Every host will always belong to at least 2 groups (`all` and `ungrouped` or `all` and some other group). Though `all` and `ungrouped` are always present, they can be implicit and not appear in group listings like `group_names`.

It's possible to put each host in **more than one group**. For example a production webserver in a datacenter in France might be included in groups called `prod` and `france` and `webservers`. It's possible create groups that track:
- **What** - An application, stack or microservice (for example, database servers, web servers, and so on).
- **Where** - A datacenter or region, to talk to local DNS, storage, and so on (for example, east, west).
- **When** - The development stage or environment, to avoid testing on production resources (for example, prod, test).

It is also possible to **nest groups**.
For example:
```
---
all:
  hosts:
    # Ungrouped hosts go here (belong to group `ungrouped`)
    free.example.com

  children:
    # Groups go here
    webserver:
      hosts:
        web1.example.com:
        web2.example.com:

    database:
      hosts:
        dba1.example.com:
        dba2.example.com

    testing:
      children:
        web1.example.com:
        dba1.example.com:

    production:
      children:
        web2.example.com:
        dba2.example.com:

    france:
      children:
        production:
        testing:
```
In this example, `free.example.com` belongs to the `ungrouped` group. `web1.example.com` and `web2.example.com` belong the `webserver` group, but only `web1.example.com` belongs in the `testing` group, `web2.example.com` belonging to the production group. However, all hosts belonging to the `production` and `testing` groups (that is, every host except `free.example.com`), also belong to the `france` group. That said, every host belongs to the `all` group.

The hosts file, as per current configuration, should be called `local` and reside in the base directory of the ansible project.

## Project structure
The ansible project is structured as follows:
```bash
.
├─ certs/              #Certificate files directory.
│   └─ certname/         #Each certificate .crt-.key pair in a different dir.
│       ├─ certname.crt
│       └─ certname.key
│
├─ keys/               #Auth key files directory, all files in the same dir.
│   ├─ key
│   └─ key.pub
│
├─ group_vars/         #Group-specific variables directory.
│   └─ groupname/        #Each group that needs specific vars has its own dir.
│       └─ vars.yml        #Many files may reside here, all will be read.
│
├─ host_vars/          #Host-specific variables directory.
│   └─ hostname/         #Each group that needs specific vars has its own dir.
│       └─ vars.yml        #Many files may reside here, all will be read.
│
├─ roles/              #User-created roles directory.
│   └─ rolename/         #Each role has its own directory.
│       ├─ files/          #Files directory.
│       │   └─ file          #Files to send reside here.
│       │
│       ├─ handlers/       #Handlers directory.
│       │   └─ main.yml      #Tasks defined here run at the end of a play if a
│       │                    #specific task has been executed.
│       │
│       ├─ meta/           #Meta directory.
│       │   └─ main.yml      #Information about the role and role dependencies
│       │                    #are defined here.
│       │
│       ├─ tasks/          #Tasks directory.
│       │   └─ main.yml      #Tasks to run on the managed nodes (hosts) are
│       │                    #defined here.
│       │
│       ├─ templates/      #Templates directory.
│       │   └─ template.j2   #Template files (e.g. for configuration files)
│       │                    #reside here.
│       │
│       └─ vars/           #Role variables directory.
│           └─ vars.yml      #Role-specific variables are defined here.
│
├─ roles_galaxy/           #Galaxy roles directory. Roles downloaded from the
│   │                      #ansible-galaxy repo are installed here.
│   └─ author.rolename/      #Each role installed in its own directory.
│
├─ ansible.cfg         #Ansible configuration file.
├─ local               #Inventory file.
├─ requirements.yml    #Requirements (dependencies) file.
├─ VAULT_PASSWORD_FILE #Vault password file, for encryption and decryption of
│                      #sensible information (passwords, api keys, etc.)
├─ initial_config.yml
├─ onm.yml
├─ dbrservers.yml
├─ dbaservers.yml
├─ stoservers.yml
├─ appservers.yml
├─ wrkservers.yml
├─ lblservers.yml
└─ README.md
```

Following this scructure, group-specific and host-specific variables can be defined. If two variables have the same name, more "spcecific" variables override more "general" variables (e.g. host variables override group variables, and role variables override host variables)

Roles are related to specific server configurations, to achieve the desired functionalities. A `common` role exists, that specifies configuration for all hosts defined in the inventory. Also, more specific ones exist, such as a `redis` role, to achieve a working Redis installation, `appworker`, that contains common configuration for `app` and `wrk` nodes, and `worker`, for `wrk` nodes, and so on.

Playbooks for each server role exist, such as `dbrservers.yml` and `appservers.yml`, that set up the needed configurations, both common and specific to the role. In addition, the `onm.yml` playbook is designed to configure every server defined in the inventory file at the same time.

## Setup

### Control node setup

#### Requirements
- Python >= 3.5
- SSH client

#### Installing ansible
Ubuntu builds are available in the official ansible PPA: https://launchpad.net/~ansible/+archive/ubuntu/ansible

To configure the PPA and install Ansible, run the following commands with root permissions:

```
# on the control node:
apt update
apt install software-properties-common
apt-add-repository --yes --update ppa:ansible/ansible
apt install ansible
```

#### Cloning the repository
Clone the Ansible repository from https://bitbucket.org/opennemas/onm-ansible/src/master/ and move its contents to `/etc/ansible`, overwriting files if necessary:
```
# on the control node:
git clone git@bitbucket.org:drjato/onm-ansible.git
mv -i onm-ansible/* /etc/ansible/
```

#### Satisfying dependencies

Dependencies are defined in a `requirements.yml`. Install the required roles and collections from said file:
```
# on the control node
ansible-galaxy role install -r requirements.yml
ansible-galaxy collection install -r requirements.yml
```

#### Vault password

Sensible data is (and must be) encrypted with ansible-vault. To be able to decrypt said data at runtime, a `VAULT_PASSWORD_FILE` must be present in the project root, containing ONLY the password used for encryption. E.g.:

`./VAULT_PASSWORD_FILE`:
```
thisisapassword
```

### Managed node setup

#### Requirements
- SSH server with SFTP support, listening on port 22.
- Python 3.5 or higher (this can be installed even through the Ansible raw module).

## Usage

### Initial configuration

Assuming that an SSH connection can be established to the managed nodes through port 22 as the root user using public key authentication, simply run the initial-config.yml playbook from the control node:

```
# on the control node
ansible-playbook -u root --private-key keys/root initial_config.yml
```

- `-u root`: connect to the host as the `root` user.
- `--private-key keys/root`: use the `root` private key under `./keys` to authenticate.
- `initial_config.yml`: the playbook to run.

This playbook will change the default SSH configuration, switching the default port to a different one (22222) and prohibiting root login, for instance. It will also create the ansible user with sudo privileges, and set up a trust relationship for said user.

### General configuration

To configure all hosts at once, simply execute the following command:
```
ansible-playbook onm.yml
```
This command will run the `onm.yml` playbook as the `ansible` user, configuring all nodes listed in the inventory.

### Per-group configuration

To configure hosts with a specific functionality (app servers, database servers, etc), different playbooks exist:

- `dbrservers.yml`: configures hosts with the Redis role (`dbr` group).
	- `common` role.
	- `redis` role.
- `dbaservers.yml`: configures hosts with the MySQL database role (`dba` group).
	- `common` role.
	- `database` role.
- `stoservers.yml`: configures hosts with the Storage role (`sto` group).
	- `common` role.
	- `storage` role.
- `appservers.yml`: configures hosts with the App role (`app` group).
	- `common` role.
	- `appworker` role.
	- `app` role.
- `wrkservers.yml`: configures hosts with the Worker role (`wrk` group).
	- `common` role.
	- `appworker` role.
	- `worker` role.
- `lblservers.yml`: configures hosts with the Load Balancer role (`lbl` group).
	- `common` role.
	- `loadbalancer` role.

All of these playbooks will run the `common` role and the roles needed for the hosts defined in that group to have the desired functionality.

To run one of these playbooks:
```
ansible-playbook <playbookfile.yml>
```

## Some ansible-playbook options

### Check hosts

To output a list of matching hosts for the execution without executing the playbook add the `--list-hosts` option. E.g.:
```
ansible-playbook --list-hosts playbookfile.yml
```

### Specify an inventory or host list

To run playbooks in hosts defined on a specific inventory file, add the `-i` or `--inventory` option. E.g.:
```
ansible-playbook -i ./myinventory
```

To run playnooks one or more hosts without an inventory file, a comma-separated host list can be specified:
```
ansible-playbook -i web.example.com, playbookfile.yml
```
In a comma-separated host list there can be no spaces, and a comma is **always** required at the end of the list. To check in which hosts the playbook will take effect, the aforementioned `--list-hosts` option can be added.

### Specify a subset of hosts

To further limit selected hosts to an additional pattern, such as a specific group, add the `-l` or `--limit` option. E.g.:
```
ansible-playbook -l groupname playbookfile.yml
```
This will run the playbook for hosts belonging to the `groupname` group specified in the default inventory.

### Run tasks one by one
To run tasks in a playbook step by step, confirming each task before running it, add the `--step` option:
```
ansible-playbook --step playbook.yml
```

### Start at specific task
To start the playbook at a specific task, the `--start-at-task` option can be added. E.g.:
```
ansible-playbook --start-at-task "Install essential packages" playbook.yml
```
This will run the "Install essential packages" task and any subsequent task.

### Run a specific task only
A dirty but functional approach to run **a specific task only** is to add both the `--start-at-task` and the `--step` options, run the desired task and then halt execution with `^C`.

### Run tagged tasks
To only run plays and tasks tagged with specific values, the `-t` or `--tags` option can be added:
```
ansible-playbook -t "config,packages" playbook.yml
```
This will only run the tasks which have the `config` or `packages` tags.

### Skip tags
To skip plays and tasks tagged with specific values, the `--skip-tags` option can be added:
```
ansible-playbook --skip-tags "config,packages"
```
This will run all tasks except those wich have the `config` or `packages` tags.

TODO: Add more use cases