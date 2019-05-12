# Date 8-Jun-2017
# Author Thor Mortensen, THM (THM@rovsing.dk)
#
require 'tty'
require_relative '../workers/user_prompter'
require_relative '../workers/manduca.rb'
require_relative 'cmd_handler'
require_relative 'rubyHelpers'

@APP_NAME       = "CommandNConquer"
pastel          = Pastel.new
logoPrinter     = LogoPrinter.new
@spinner        = TTY::Spinner.new("Sending package ".brown + ":spinner".blue, format: :arrow_pulse)
@simplePrompter = TTY::Prompt.new(interrupt: :signal)
$sigExitMsg     = "\nExiting. Use 'b' to go back (Noting was sent)"
@initDone       = false

def exitPoint
  puts $sigExitMsg
  exit 130
end

@betweenLambda   = -> input {input.is_integer? && input.to_i.between?(0, 255)}
@eatHexLambda    = -> input {input.is_hex? or input.is_integer?}
@convHexLambda    = -> input {
 if input.is_hex? 
  input.match(/0x([a-fA-F0-9]+)/)[1].to_i(16)
 else 
  input.to_i
 end 
}
@betweenErrorMsg = "Must be (or produce) a number between 0 and 255".red
UserPrompter.setSignalExitMsg($sigExitMsg)
@connectionFuckUpDefaultAnsw = true

@cmdPrompt  = UserPrompter.new("Enter CMD  ".green, 
                                @APP_NAME+"-CMD", 
                                acceptedInput_lambda: @betweenLambda, 
                                errorMsg: @betweenErrorMsg
                                )
@arg1Prompt = UserPrompter.new("Enter Arg1 ".magenta, @APP_NAME+"-ARG1", acceptedInput_lambda: @eatHexLambda)
@arg2Prompt = UserPrompter.new("Enter Arg2 ".cyan, @APP_NAME+"-ARG2", acceptedInput_lambda: @eatHexLambda)

# Setup the prompt order loop
@cmdPrompt >> @arg1Prompt >> @arg2Prompt
@cmdPrompt << @cmdPrompt # Tie up the back-loop so it doesn't crash when user goes back from fresh start
@ipPromter = Manduca.new(promtMsg: "",
            # defaultAnswer: "",
            defaultAnswerLastInput: true,
            useDefaultOnEnter: true,
            historyFileName: @APP_NAME+"-ipPromter" ,
            sigIntCallback: method(:exitPoint),
            )


def startPrompt

  device = @simplePrompter.select("Select device:", %w(MASC SLP SLP100))

  if @deviceIP.nil? or @initDone
    case device
      when "MASC"
        defaultIp = "192.168.52."
      when "SLP"
        defaultIp = "192.168.51."
      when "SLP100"
        defaultIp = "192.168.53."
    end

    while true

      @deviceIP = @ipPromter.prompt(promtMsg: "What's the #{device} ip? ~> ", defaultAnswer: defaultIp)

      if @deviceIP.match(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/)
        puts "Device IP: " + @deviceIP.green
        @ipPromter.saveInputStr
        break
      else
        puts "Not a valid IP address".red
        next
      end
    end

    exitPoint

  end

  cmdHandler = CmdHandler.new(@deviceIP)

  unless @initDone
    puts "~~~~~~~~~~~~{ How to use this script }~~~~~~~~~~~~".bg_blue.bold
    UserPrompter.printHelp
  end

  case device
    when "MASC"
      runMasc(cmdHandler)
    when "SLP"
      runSlp(cmdHandler)
  end

  @initDone = true

end


def txCmd(cmdHandler, cmd, arg1, arg2)
  puts
  @spinner.auto_spin

  begin
    cmdHandler.sendCmd(cmd, arg1, arg2, doloopbackTest: true)
  rescue => e
    @spinner.stop(e.to_s.bold.red)
    msg = "Something went wrong with the network. Select new IP?"
    if @connectionFuckUpDefaultAnsw 
      answ = @simplePrompter.yes?(msg)
      @connectionFuckUpDefaultAnsw = answ
      return !answ
    else 
      answ = @simplePrompter.no?(msg)
      @connectionFuckUpDefaultAnsw = !answ
      return answ
    end 
  end

  @spinner.stop('done!'.bold.green)
  cmdHandler.print_package
  return true
end

def printInputHelp
  puts "Input:".bold #
  puts "  Enter command (cmd) number and argument (arg) value when prompted or\n"
  puts "  you can enter a lambda as input to automate the input value.       \n"
  puts "  The lambda input will receive the last input result as a parameter.\n"
  puts "  Lambda input examples:                                             \n"
  puts "                                                                     \n"
  puts "    - To increment input by 1                                          ".bold
  puts "        -> res {res + 1}                                              ".blue
  puts "    - To make one-hot (bit) encoding input                             ".bold
  puts "        1 -> res {res + res}                                          ".blue
  puts "                                                                     \n"
  puts "  A number before the arrow will be used as initial input to lambda. \n"
  puts "  If no number is given, the last input will be used.                \n"
  puts
end


def strToInt(str)
  if str.length > 8
    puts "String is longer than 8 (#{ str.length })"
    return nil, nil 
  end 

  arg1 = 0
  arg2 = 0

  d = 3
  str[0..3].each_byte do |i|
    c = i.ord.to_i
    arg1 |= c  << (8 * d) # Fixnum#chr converts any number to the ASCII char it represents
    d -= 1
  end

  d = 3
  str[4..7].each_byte do |i|
    arg2 |= i.ord.to_i  << (8 * d) # Fixnum#chr converts any number to the ASCII char it represents
    d -= 1
  end

  return arg1, arg2

end 

  DISP_INFO_CONTROL = 187
  DISP_INFO_LHS = 183
  DISP_INFO_RHS = 185

  SELECT_DISPLAYED_FUNCTION  = 0
  SET_FUNCTION_COUNT = 1
  SET_FUNCTION_LED = 2

def runRemoteDisp(cmdHandler)
  ledMap = [59,58,57,56, 4,3,2,1,0]
  functionCount = ledMap.size

  val1 = 0
  val2 = 0

  cmd = DISP_INFO_CONTROL

  puts "----- Initializing DispInfo -----"

  puts "Setting function count to #{functionCount}"
  arg1 = SET_FUNCTION_COUNT
  arg2 = functionCount

  return unless txCmd(cmdHandler, cmd, arg1, arg2)

  puts "Setting LED map #{ledMap}"

  ledMap.each_with_index do |val, index|
    arg1 = SET_FUNCTION_LED
    val1 = index
    val2 = val
    arg2 = val1 | (val2 << 16)
    return unless txCmd(cmdHandler, cmd, arg1, arg2)
  end



  intergerFy = -> str {
    arg1 = 0

    d = 3

    str[0..3].each_byte do |i|
      c = i.ord.to_i
      arg1 |= c  << (8 * d) # Fixnum#chr converts any number to the ASCII char it represents
      d -= 1
    end
    return arg1
  }


  dispIndex    = UserPrompter.new("DispFunction Index ".bold)
  lhsStr    = UserPrompter.new("LHS   ".bold, -> input {input.length <= 4}, 'Must be shorter than 4', intergerFy)
  rhsStr    = UserPrompter.new("RHS   ".bold, lhsStr)
  dotLhs    = UserPrompter.new("Dot L ".bold, -> input {input.is_integer? && input.to_i <= 4},
                               'Must be shorter than 4', -> int {(int.to_i > 0) ? (8 >> (int.to_i - 1)) : 0})
  dotRhs    = UserPrompter.new("Dot R ".bold, dotLhs)


  dispIndex >> lhsStr >> rhsStr >> dotLhs >> dotRhs
  dispIndex << dispIndex # Tie up the back-loop so it doesn't crash when user goes back from fresh start


  while true 
    dispIndex.runPrompt

    cmd = DISP_INFO_LHS
    return if dispIndex.result == 99

    arg1 = (dispIndex.result | (dotLhs.result << 16))
    
    arg2 = lhsStr.result
    return unless txCmd(cmdHandler, cmd, arg1, arg2)

    cmd = DISP_INFO_RHS

    arg1 = (dispIndex.result | (dotRhs.result << 16))

    arg2 = rhsStr.result
    return unless txCmd(cmdHandler, cmd, arg1, arg2)

  end 


end 

def runMasc(cmdHandler)

  printInputHelp

  # Extra prompt for MASC shm
  shmChmCmdPrompt    = UserPrompter.new("Shm CMD    ".bold, @APP_NAME+"-SHM_CMD",  acceptedInput_lambda: @eatHexLambda)
  shmCmdExdCmdPrompt = UserPrompter.new("Shm cmdExd ".bold, @APP_NAME+"-SHM_ARG1", acceptedInput_lambda: @eatHexLambda)
  shmIndexCmdPrompt  = UserPrompter.new("Shm index  ".bold, @APP_NAME+"-SHM_ARG2", acceptedInput_lambda: @eatHexLambda)

  # dic  = UserPrompter.new("Display Info Control cmd  ".bold, @cmdPrompt, @eatHexLambda)
  # div1  = UserPrompter.new("Display Info Control val1  ".bold, @cmdPrompt, @eatHexLambda)
  # div2  = UserPrompter.new("Display Info Control val2  ".bold, @cmdPrompt, @eatHexLambda)

  # Connecting extra prompts to main prompt loop
  @cmdPrompt >> {-> cmd {cmd.to_i.between? 160, 163} => shmChmCmdPrompt >> shmCmdExdCmdPrompt >> shmIndexCmdPrompt >> @arg2Prompt}

  # @cmdPrompt >> {-> cmd {cmd.to_i == 187} => dic >> div1 >> div2 >> @arg2Prompt}

  while true
    @cmdPrompt.runPrompt

    cmd = @cmdPrompt.result

    if cmd == 255
      while true 
       runRemoteDisp cmdHandler
      end 
    end 

    if @cmdPrompt.didBranch
      shmCmd   = shmChmCmdPrompt.result
      shmCmdEx = shmCmdExdCmdPrompt.result
      shmIndex = shmIndexCmdPrompt.result
      arg1     = shmCmd << 16 | shmCmdEx << 8 | shmIndex
    else
      arg1 = @arg1Prompt.result
    end
    arg2 = @arg2Prompt.result

    return unless txCmd(cmdHandler, cmd, arg1, arg2)
  end
end

def runSlp(cmdHandler)

  printInputHelp

  while true
    @cmdPrompt.runPrompt

    cmd  = @cmdPrompt.result
    arg1 = @arg1Prompt.result
    arg2 = @arg2Prompt.result
    
    return unless txCmd(cmdHandler, cmd, arg1, arg2)


    # cmd1  = 75
    # cmd2  = 76
    # arg1 = 1
    # arg2 = 1

    # for i in 0..5 
      # return unless txCmd(cmdHandler, cmd1, arg1, arg2)
      # return unless txCmd(cmdHandler, cmd2, arg1, arg2)
    # end

  end
end


############################################
# MAIN
############################################
@deviceIP = ARGV[0]
# @deviceIP = "127.0.0.1"
ARGV.clear

logoPrinter.paintRovLogo(pastel.yellow("Command\n&\nConquer\n".bold) + "\n (SLP and MASC)".bold)
puts

while true
  startPrompt
end

# Things to add
# - Main meny                             - OK
# - Package tabel + resqueb               - OK
# - Help section                          - semi OK
# - Back                                  - OK
# - history                               - OK
# - accept math function                  - OK
# - Fix delete                            - OK
#  -clone if given as arg in constructer  - OK
#



