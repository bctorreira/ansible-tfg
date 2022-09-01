# Test the "common" role.

# Check SSH server configuration
describe sshd_config do
    its('Port') { should cmp 22 }
    its('PermitRootLogin') { should cmp 'no' }
    its('IgnoreUserKnownHosts') { should cmp 'yes' }
    its('X11Forwarding') { should cmp 'no' }
end

# Check if SSH service is running
describe service('ssh') do
    it { should be_enabled }
    it { should be_installed }
    it { should be_running }
end

# Check if default SSH port (22) is listening
describe port(22) do
    it { should be_listening }
end

# Check correct timezone
describe timezone do
  its('identifier') { should eq 'Etc/UTC' }
end

# Check for users
my_users = yaml(content: inspec.profile.file('users.yml')).params
my_users.each do |u|
    describe user(u) do
        it { should exist }
    end
end

# Check for installed packages
my_packages = yaml(content: inspec.profile.file('packages.yml')).params
my_packages.each do |p|
    describe package(p) do
        it { should be_installed }
        it { should be_latest }
    end
end

# Check for files
my_files = yaml(content: inspec.profile.file('files.yml')).params
my_files.each do |f|
    describe file(f) do
        it { should exist }
        it { should be_file }
        its('size') { should_not be 0 }
    end
end

# Check for successful netdata installation
describe file('/opt/netdata/etc/netdata/netdata.conf') do
    it { should exist }
    it { should be_file }
    its('size') { should_not be 0 }
    its('mode') { should cmp 0644 }
end
describe service('netdata') do
    it { should be_enabled }
    it { should be_installed }
    it { should be_running }
end