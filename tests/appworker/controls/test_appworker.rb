# Test the "appworker" role.


# Check for users
my_users = yaml(content: inspec.profile.file('users.yml')).params
my_users.each do |u|
    describe user(u) do
        it { should exist }
    end
end

# Check for sent files
my_files = yaml(content: inspec.profile.file('files.yml')).params
my_files.each do |f|
    describe file(f) do
        it { should exist }
        it { should be_file }
        its('size') { should_not be 0 }
    end
end

# Check for nfs mounts
my_mounts = yaml(content: inspec.profile.file('nfs.yml')).params
my_mounts.each do |m|
    describe mount(m) do
        it { should be_mounted }
        its('type') { should eq 'nfs' }
    end
end

# Check for php repository
describe apt('ppa:ondrej/php') do
    it { should exist }
    it { should be_enabled }
end

# Check for php packages
my_packages = yaml(content: inspec.profile.file('php_packages.yml')).params
my_packages.each do |p|
    describe package(p) do
        it { should be_installed }
        it { should be_latest }
    end
end

# Check for php config files
my_files = yaml(content: inspec.profile.file('php_files.yml')).params
my_files.each do |f|
    describe file(f) do
        it { should exist }
        it { should be_file }
        its('size') { should_not be 0 }
    end
end

# Check if php service is up
describe service('php7.3-fpm') do
    it { should be_enabled }
    it { should be_installed }
    it { should be_running }
end
