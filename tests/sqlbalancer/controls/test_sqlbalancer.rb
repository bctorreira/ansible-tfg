# Test the "sqlbalancer" role.


# Check for mariadb repository
describe apt('deb https://mirrors.chroot.ro/mariadb/repo/10.6/ubuntu focal main') do
    it { should exist }
    it { should be_enabled }
end

# Check for proxysql repository
describe apt('deb https://repo.proxysql.com/ProxySQL/proxysql-2.2.x/focal/ ./') do
    it { should exist }
    it { should be_enabled }
end

# Check for installed packages
my_packages = yaml(content: inspec.profile.file('packages.yml')).params
my_packages.each do |p|
    describe package(p) do
        it { should be_installed }
        it { should be_latest }
    end
end

# Check for config files
my_files = yaml(content: inspec.profile.file('config_files.yml')).params
my_files.each do |f|
    describe file(f) do
        it { should exist }
        it { should be_file }
        its('size') { should_not be 0 }
    end
end

# Check if proxysql service is running
describe service('proxysql') do
    it { should be_enabled }
    it { should be_installed }
    it { should be_running }
end

# Check if keepalived service is running
describe service('keepalived') do
    it { should be_enabled }
    it { should be_installed }
    it { should be_running }
end

# Check if proxysql port (6033) is listening
describe port(22) do
    it { should be_listening }
end