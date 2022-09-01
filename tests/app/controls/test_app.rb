# Test the "app" role.

# Check for nginx packages
my_packages = yaml(content: inspec.profile.file('nginx_packages.yml')).params
my_packages.each do |p|
    describe package(p) do
        it { should be_installed }
        it { should be_latest }
    end
end

# Check for nginx config files
my_files = yaml(content: inspec.profile.file('nginx_config_files.yml')).params
my_files.each do |f|
    describe file(f) do
        it { should exist }
        it { should be_file }
        its('size') { should_not be 0 }
    end
end

# Check if default files removed
my_files = yaml(content: inspec.profile.file('nginx_removed_files.yml')).params
my_files.each do |f|
    describe file(f) do
        it { should_not exist }
    end
end

# Check if nginx service is up
describe service('nginx') do
    it { should be_enabled }
    it { should be_installed }
    it { should be_running }
end
