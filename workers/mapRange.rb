require 'tty'
require_relative 'rubyHelpers.rb'
require_relative 'manduca.rb'


# Look here for explanation and inspiration:
# https://stackoverflow.com/questions/5731863/mapping-a-numeric-range-onto-another


helpStr = "Argument list: from_range_low from_range_high to_range_low to_range_high from_range_number (decimal points)"

class RangeMapper

  def initialize label, fromStart = nil, fromEnd = nil, toStart = nil, toEnd = nil, input = nil, decimals = nil
    @label = label
    
    @prompt = TTY::Prompt.new(interrupt: :exit)
    load
    # if @fromStart.nil?
    #   promptRange
    # else 
    #   # @fromStart = fromStart
    #   # @fromEnd = fromEnd
    #   # @toStart = toStart
    #   # @toEnd = toEnd
    # end 

  end 

  def setRange
    @fromStart = @p_fromStart.getDefaultAnsw
    @fromEnd = @p_fromEnd.getDefaultAnsw
    @toStart = @p_toStart.getDefaultAnsw
    @toEnd = @p_toEnd.getDefaultAnsw
    @decimals = @p_decimals.getDefaultAnsw
  end


  def load 
    #TODO make load from file here 
    @p_fromStart = getPromter "p_fromStart", "From range start ~> "
    @p_fromEnd = getPromter "p_fromEnd", "From range end ~> "
    @p_toStart = getPromter "p_toStart", "To range start ~> "
    @p_toEnd = getPromter "p_toEnd", "To range end ~> "
    @p_input = getPromter "p_input", "Input ~> "
    @p_decimals = getPromter "p_decimals", "Result decimals ~> "
    
    setRange

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

  def validate prompt
    while (answ = parseInput(prompt.prompt)) == nil
    end 
    prompt.saveInputStr
    setRange
  end 

  def promptInput 
    answ = nil

    until !answ.nil?
      input = @p_input.prompt 
      if input == "c" 
        promptRange
        next
      end 

      fromStart = parseInput(@fromStart)
      fromEnd = parseInput(@fromEnd)
      toStart = parseInput(@toStart)
      toEnd = parseInput(@toEnd)
      decimals = parseInput(@decimals)

      answ = parseInput(input, true)

      if answ.nil? || answ < fromStart || answ > fromEnd 
        puts "#{answ} is not in range #{fromStart} to #{fromEnd}"
        answ = nil
      end 
    end 
    calc answ, fromStart, fromEnd, toStart, toEnd, decimals
  end 

  def thisIs 
   ["From start : #{@fromStart}",
    "From end   : #{@fromEnd}",
    "To start   : #{@toStart}",
    "To end     : #{@toEnd}",
    "Decimals   : #{@decimals}"]
  end 

  def details
    is = thisIs
    puts "#{is[0]}"
    puts "#{is[1]}"
    puts "------------"
    puts "#{is[2]}"
    puts "#{is[3]}"
    puts "------------"
    puts "#{is[4]}"
  end   

  def promptRange
    
    again = true

    while again
      is = thisIs
      answ = @prompt.select("Change range".bold) do |menu|
        menu.choice "#{is[0]}", 1
        menu.choice "#{is[1]}", 2
        menu.choice "#{is[2]}", 3
        menu.choice "#{is[3]}", 4
        menu.choice "#{is[4]}", 5
        menu.choice "Swap", 6
        menu.choice "Back", 7
      end

      case answ
      when 1
        validate @p_fromStart
      when 2
        validate @p_fromEnd
      when 3
        validate @p_toStart
      when 4
        validate @p_toEnd
      when 5
        validate @p_decimals
      when 6
        swap
      when 7
        again = false 
        break
      end 
    end 
  end 


  def calc input, fromStart, fromEnd, toStart, toEnd, decimals
    slope = 1.0 * (toEnd - toStart) / (fromEnd - fromStart)
    (toStart + slope * (input - fromStart)).round(decimals)
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

    tempFromStart = @fromStart 
    tempFromEnd = @fromEnd

    @fromStart = @toStart
    @fromEnd = @toEnd

    @toStart = tempFromStart
    @toEnd = tempFromEnd

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
puts "#{defRange.details}"

while true 
  input = defRange.promptInput
  puts "=> #{input}     0x#{input.to_i.to_s(16)} "

end 
