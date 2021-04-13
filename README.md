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


## Usage
### Initial setup

After defining the inventory, execute the following command to run a playbook that configures the SSH service and creates an `ansible` user in all hosts:
```
ansible-playbook -u root --private-key keys/root initial_config.yml
```

- `-u root`: connect to the host as the `root` user.
- `--private-key keys/root`: use the `root` private key under `./keys` to authenticate.
- `initial_config.yml`: the playbook to run.

The hosts will begin to listen for SSH connections at port 22222, and will prohibit `root` logins.

### Host configuration

To configure all hosts at once, simply execute the following command:
```
ansible-playbook onm.yml
```
This command will run the `onm.yml` playbook as the `ansible` user, configuring all nodes listed in the inventory.

### Per-role configuration

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

All of these playbooks will run the `common` role and the roles needed for the host to have the desired functionality.