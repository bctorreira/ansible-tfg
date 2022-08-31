# Test the "common" role.

# Get package list
my_packages = yaml(content: inspec.profile.file('packages.yml')).params

# Check for installed packages
my_packages.each do |p|
    describe package(p) do
        it { should be_installed }
        it { should be_latest }
    end
end

# Get user list
my_users = yaml(content: inspec.profile.file('users.yml')).params

# Check for users
my_users.each do |u|
    describe user(u) do
        it { should exist }
    end
end

# Get file list
my_files = yaml(content: inspec.profile.file('files.yml')).params

# Check for files
my_files.each do |f|
    describe file(f) do
        it { should exist }
        it { should be_file }
        its('size') { should_not be 0 }
    end
end