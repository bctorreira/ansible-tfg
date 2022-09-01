# Test the "redis" role.

# Check for redis package
describe package('redis-server') do
    it { should be_installed }
    it { should be_latest }
end

# Check for config file
describe file('/etc/redis/redis.conf') do
    it { should exist }
    it { should be_file }
    its('size') { should_not be 0 }
end

# Check if redis service is running
describe service('redis-server') do
    it { should be_enabled }
    it { should be_installed }
    it { should be_running }
end

# Check redis port is listening
describe port(6379) do
    it { should be_listening }
end
