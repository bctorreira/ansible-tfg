# Test the "common" role.


# Check for nfs packages
my_packages = yaml(content: inspec.profile.file('packages.yml')).params
my_packages.each do |p|
    describe package(p) do
        it { should be_installed }
        it { should be_latest }
    end
end

# Check rpc ports
my_ports = yaml(content: inspec.profile.file('ports.yml')).params
my_ports.each do |p|
    describe port(P) do
        it { should be_listening }
    end
end

# Check for directories
my_files = yaml(content: inspec.profile.file('directories.yml')).params
my_files.each do |d|
    describe directory(d) do
        it { should exist }
        it { should be_readable }
        it { should be_writable }
    end
end
