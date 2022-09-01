# Test the "worker" role.

# Check for backupninja packages
describe package('backupninja') do
    it { should be_installed }
    it { should be_latest }
end

# Check for backupninja config files
my_files = yaml(content: inspec.profile.file('backupninja_config_files.yml')).params
my_files.each do |f|
    describe file(f) do
        it { should exist }
        it { should be_file }
        its('size') { should_not be 0 }
    end
end

# Check directories for mysqldump
my_dirs = yaml(content: inspec.profile.file('mysqldum_dirs.yml')).params
my_dirs.each do |d|
    describe directory(d) do
        it { should exist }
    end
end