require 'tty'

require_relative 'rubyHelpers.rb'
require_relative '../workers/manduca.rb'
require_relative 'regDescription.rb'


register = ARGV[0]
arg1 = ARGV[1]
# arg2 = ARGV[2]
ARGV.clear

trap "SIGINT" do
  exit 130
end


@simplePrompter = TTY::Prompt.new(interrupt: :signal)






runForEver = true

lastReg = ""
lastStatusBits = 0

register = @registers.keys[0]

while (runForEver)



  register = @simplePrompter.select("Please select register to parse:", @registers.keys,  default: @registers.keys.index(register)+1)

  table = @registers[register]
  isOk = false

  @reg = Manduca.new(promtMsg: "",
              # defaultAnswer: "",
              # defaultAnswerLastInput: true,
              useDefaultOnEnter: true,
              historyFileName: "regParser-#{register}" ,
              # sigIntCallback: method(:exitPoint),
              )

  if arg1.nil? 
    until isOk 

      statusBits =  @reg.prompt( promtMsg: "Enter #{register} (in hex) ~> ").to_i(16)
      if statusBits == 0
        puts "Not a valid register value! Please try again..."
      else 
        isOk = true
        @reg.saveInputStr
      end           
    end 
  else
    statusBits = arg1.to_i(16)
    runForEver = false
  end

  bitdex = 0


  puts '+-----+-------+-------------+'
  puts '| Bit | State | Description |' 
  puts '+-----+-------+-------------+'
  sbBac = statusBits

  for i in table
    mark = ' '

    if lastReg == register 
      mark = '*' if ((statusBits & 1) != (lastStatusBits & 1))
    end 

    puts "|  #{' ' if bitdex < 10}#{bitdex} |   #{statusBits&0x1 == 1 ? "1".red : "0".green}#{mark}  | #{i.to_s}" 
    bitdex += 1
    statusBits >>= 1
    lastStatusBits >>= 1
  end 

  lastReg = register
  lastStatusBits = sbBac 
end 