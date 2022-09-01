# Test the "database" role.

# Check if apparmor service is NOT RUNNING
describe service('apparmor') do
    it { should_not be_running }
end

# Check for mariadb repository
describe apt('https://mirrors.chroot.ro/mariadb/repo/10.6/ubuntu') do
    it { should exist }
    it { should be_enabled }
end

# Check for installed packages (mariadb, galera...)
my_packages = yaml(content: inspec.profile.file('packages.yml')).params
my_packages.each do |p|
    describe package(p) do
        it { should be_installed }
        it { should be_latest }
    end
end

# Check for galera config file
describe file('/etc/mysql/mariadb.conf.d/60-galera.cnf') do
    it { should exist }
    it { should be_file }
    its('size') { should_not be 0 }
end

# Check if mysql service is running
describe service('mysql') do
    it { should be_running }
end

# Check if mysql port (3306) is listening
describe port(3306) do
    it { should be_listening }
end
