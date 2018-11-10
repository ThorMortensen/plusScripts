
require 'tty'


# @deviceIP = ARGV[0]
# ARGV.clear


dir = '..'

thr = Thread.new { sleep }
thr.status # => "sleep"

count = Dir[File.join(dir, '**', '*')].count { |file| File.file?(file) }
puts count