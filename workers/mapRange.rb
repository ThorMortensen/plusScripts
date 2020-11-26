require 'tty'
require_relative 'rubyHelpers.rb'
require_relative 'manduca.rb'


# Look here for explanation and inspiration:
# https://stackoverflow.com/questions/5731863/mapping-a-numeric-range-onto-another


helpStr = "Argument list: from_range_low from_range_high to_range_low to_range_high from_range_number (decimal points)"

class RangeMapper

  def initialize label, fromStart = nil, fromEnd = nil, toStart = nil, toEnd = nil, input = nil, decimals = nil
    @label = label
    load
    if fromStart.nil?
      promptRange
    else 
      @fromRange = fromStart..fromEnd
      @toRange = toStart..toEnd
      @decimals = decimals.nil? ? 3 : decimals
    end 

  end 

  def load 
    #TODO make load from file here 
    @p_fromStart = getPromter "p_fromStart", "From range start ~> "
    @p_fromEnd = getPromter "p_fromEnd", "From range end ~> "
    @p_toStart = getPromter "p_toStart", "To range start ~> "
    @p_toEnd = getPromter "p_toEnd", "To range end ~> "
    @p_input = getPromter "p_input", "Input ~> "
    @p_decimals = getPromter "p_decimals", "Result decimals ~> "

    # puts "#{@p_fromStart}"


    @fromRange = @p_fromStart.getDefaultAnsw..@p_fromEnd.getDefaultAnsw
    @toRange = @p_toStart.getDefaultAnsw..@p_toEnd.getDefaultAnsw
    @decimals = @p_decimals.getDefaultAnsw
  end

  def getPromter name, msg 
      Manduca.new(promtMsg: msg,
                  # defaultAnswer: "",
                  defaultAnswerLastInput: true,
                  useDefaultOnEnter: true,
                  historyFileName: "mapRange" + "-#{@label}-#{name}",
                  # sigIntCallback: method(:exitPoint),
      )

  end 

  def validate promt
    while (answ = parseInput(promt.prompt)) == nil
    end 
    promt.saveInputStr

  end 

  def promptInput 
    answ = nil

    until !answ.nil?
      answ = parseInput(@p_input.prompt, true)
      unless @fromRange.include? answ 
        puts "#{answ} is not in range #{@fromRange}"
        answ = nil
      end 
    end 
    calc answ
  end 

  def promptRange
    
    validate @p_fromStart.prompt
    validate @p_fromEnd.prompt
    validate @p_toStart.prompt
    validate @p_toEnd.prompt
    validate @p_decimals.prompt

  end 


  def calc input  
    @slope = 1.0 * (@toRange.last - @toRange.first) / (@fromRange.last - @fromRange.first)
    @toRange.first + @slope * (input - @fromRange.first)
  end


  def parseInput input, verbose = false
    begin
      i = eval(input)
    rescue
      if verbose
        puts "Not a valid input: #{input}".red
      end
      i = nil
    end 
    return i
  end 

  def swap
    tempFrom = @fromRange 
    @fromRange = @toRange 
    @toRange = tempFrom
  end 

end 

# if ARGV.length <= 1 && ARGV.length <= 5
#   puts "Wrong numbers of arguments"
#   puts helpStr
# else 
#   @fromStart = parseInput ARGV[0], true
#   @fromEnd = parseInput ARGV[1], true
#   @toStart = parseInput ARGV[2], true
#   @toEnd  = parseInput ARGV[3], true
#   @input = parseInput ARGV[4], true
#   # @decimals = parseInput ARGV[5], true
#   init
#   result = mapFromRangeToAnotherRange 
#   puts "#{result}    0x#{result.to_i.to_s(16)}"
# end  

defRange = RangeMapper.new "default"

puts "answer: #{defRabger}"

# puts "parseInput: #{parseInput ARGV[0]}"

# device = ARGV[0]
# cmd = ARGV[1]
# ipId = ARGV[2]
# ARGV.clear



# setup:
# - swap 
# - input range high 
# - input range low
# - output range high 
# - output range low
# - decimals

# input: zzz 0xzzz
# output: yyy 0xyyy


# current setup:

# input
# setup 
# 
