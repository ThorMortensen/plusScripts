require_relative 'rubyHelpers.rb'
require_relative 'regDescription.rb'


tableName = ARGV[0]
arg1 = ARGV[1]
# arg2 = ARGV[2]
ARGV.clear


table = @registers[tableName.intern]
runForEver = true

while (runForEver)
  if arg1.nil? 
    puts "Enter #{tableName} (in hex)"
    statusBits = gets.to_i(16)
  else
    runForEver = false
    statusBits = arg1.to_i(16)
  end

  bitdex = 0

  puts '+-----+-------+-------------+'
  puts '| Bit | State | Description |' 
  puts '+-----+-------+-------------+'

  for i in table
    puts "|  #{' ' if bitdex < 10}#{bitdex} |   #{statusBits&0x1 == 1 ? "1".red : "0".green}   | #{i.to_s}" 
    bitdex += 1
    statusBits >>= 1
  end 

end 