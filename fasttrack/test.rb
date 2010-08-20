require 'rubygems'
require 'net/ssh'

Net::SSH.start('localhost', 'paulj') do |ssh|
  ssh.exec!('bash')
end
