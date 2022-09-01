# Test the "loadbalancer" role.

# Check for installed packages (varnish and nginx)
my_packages = yaml(content: inspec.profile.file('packages.yml')).params
my_packages.each do |p|
    describe package(p) do
        it { should be_installed }
        it { should be_latest }
    end
end

# Check for config files (varnish and nginx)
my_files = yaml(content: inspec.profile.file('config_files.yml')).params
my_files.each do |f|
    describe file(f) do
        it { should exist }
        it { should be_file }
        its('size') { should_not be 0 }
    end
end

# Check for users
my_users = yaml(content: inspec.profile.file('users.yml')).params
my_users.each do |u|
    describe user(u) do
        it { should exist }
    end
end

# Check if varnish and nginx services are up
describe service('nginx') do
    it { should be_enabled }
    it { should be_installed }
    it { should be_running }
end
describe service('varnish') do
    it { should be_enabled }
    it { should be_installed }
    it { should be_running }
end
describe service('varnishncsa') do
    it { should be_enabled }
    it { should be_installed }
    it { should be_running }
end

# Check listening ports
# Check if HTTP port (80) is listening
describe port(80) do
    it { should be_listening }
# Check if HTTPS port (443) is listening
describe port(443) do
    it { should be_listening }
end
