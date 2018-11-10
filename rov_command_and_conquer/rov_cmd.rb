# Date 8-Jun-2017
# Author Thor Mortensen, THM (THM@rovsing.dk)
#
require 'tty'
require_relative '../user_prompter'
require_relative 'cmd_handler'
require_relative 'rubyHelpers'

pastel          = Pastel.new
logoPrinter     = LogoPrinter.new
@spinner        = TTY::Spinner.new("Sending package ".brown + ":spinner".blue, format: :arrow_pulse)
@simplePrompter = TTY::Prompt.new(interrupt: :signal)
$sigExitMsg     = "\nExiting. Use 'b' to go back (Noting was sent)"
@initDone       = false

trap "SIGINT" do
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

@cmdPrompt  = UserPrompter.new("Enter CMD  ".green, @betweenLambda, @betweenErrorMsg)
@arg1Prompt = UserPrompter.new("Enter Arg1 ".magenta, @eatHexLambda)
@arg2Prompt = UserPrompter.new("Enter Arg2 ".cyan, @eatHexLambda)

# Setup the prompt order loop
@cmdPrompt >> @arg1Prompt >> @arg2Prompt
@cmdPrompt << @cmdPrompt # Tie up the back-loop so it doesn't crash when user goes back from fresh start

def startPrompt

  device = @simplePrompter.select("Select device:", %w(MASC SLP))

  if @deviceIP.nil? or @initDone
    case device
      when "MASC"
        defaultIp = "192.168.52."
      when "SLP"
        defaultIp = "192.168.51."
    end

    while true
      @deviceIP = @simplePrompter.ask("What's the #{device} ip?", default: defaultIp + "xx") do |q|
        q.required(true)
        q.validate(/(\d{1,3}|\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)/, "Not a valid IP address")
      end
      if @deviceIP == defaultIp + "xx"
        puts "Not a valid IP address".red
        next
      end
      unless @deviceIP.match(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/)
        @deviceIP = defaultIp + @deviceIP
        puts "Device IP: " + @deviceIP.green

      end
      break
    end

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
    cmdHandler.sendCmd(cmd, arg1, arg2)
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


def runMasc(cmdHandler)

  printInputHelp

  # Extra prompt for MASC shm
  shmChmCmdPrompt    = UserPrompter.new("Shm CMD    ".bold, @cmdPrompt, @eatHexLambda)
  shmCmdExdCmdPrompt = UserPrompter.new("Shm cmdExd ".bold, @cmdPrompt, @eatHexLambda)
  shmIndexCmdPrompt  = UserPrompter.new("Shm index  ".bold, @cmdPrompt, @eatHexLambda)

  # Connecting extra prompts to main prompt loop
  @cmdPrompt >> {-> cmd {cmd.to_i.between? 160, 163} => shmChmCmdPrompt >> shmCmdExdCmdPrompt >> shmIndexCmdPrompt >> @arg2Prompt}

  while true
    @cmdPrompt.runPrompt

    cmd = @cmdPrompt.result
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



