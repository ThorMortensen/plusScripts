#   Auther  : thm
#   Date    : 11-Aug-2018
#   Project : scripts
#
#   Description:
#     This prompter is intended for use for collecting lots
#     of user data with the ability for the user to go back
#     in the middle of input to change data values or branch
#     to a new input. See the README for examples and how to use it.

require 'tty'
require_relative 'rubyHelpers.rb'
require_relative 'manduca.rb'

class UserPrompter

  attr_reader :promptStr, :checkValidInput, :errorMsg, :inputConverter_lambda, :nextPrompt, :prevPrompt, :didBranch


  @controlKeys = {'r' => :autoRun, 'b' => :back, 'h' => :help, 'q' => :quit}
  @@sigExitMsg = "Exiting."

  def self.setSignalExitMsg msg
    @@sigExitMsg = msg
  end


  # @param [String] promptStr
  def initialize(promptStr, 
                 appName, 
                 cloneSettingsFrom: nil,
                 acceptedInput_lambda: -> input {input.is_integer?}, 
                 errorMsg: 'Must be (or produce) a number', 
                 inputConverter_lambda: -> input {input.to_i},
                 exitPoint: Manduca.method(:exitPoint)
                 )
    @nextPrompt      = []
    @cursor          = TTY::Cursor
    # @reader          = TTY::Reader.new(interrupt: -> {puts @@sigExitMsg; exit(1)})
    @cli = Manduca.new(promtMsg: promptStr,
                       # defaultAnswer: "",
                       defaultAnswerLastInput: true,
                       useDefaultOnEnter: true,
                       # historyFilePath: "~/.manduca-history",
                       historyFileName: appName ,
                       sigIntCallback: exitPoint,
                       )

    @branchCond      = -> res {false}
    @lastLambdaInput = nil
    @ppState         = :start
    @ppCaller        = :user
    @didBranch       = false


    @promptStr = promptStr

    @checkValidInput = acceptedInput_lambda
    @inputConverter_lambda = inputConverter_lambda
    @errorMsg = errorMsg


    if cloneSettingsFrom.is_a?(UserPrompter) # Clone rest of the parameters from any incoming objects of the same type
      @errorMsg              = cloneSettingsFrom.errorMsg
      @inputConverter_lambda = cloneSettingsFrom.inputConverter_lambda
      @checkValidInput       = cloneSettingsFrom.checkValidInput
    end 
  end

  def getFormattedPromptStr(promptStr)
    "#{promptStr}#{
    (@lastInput.nil? and @lastLambdaInput.nil?) ?
        '' :
        '(' + @lastInput.to_s.gray.dim + ')'} ~> "
  end


  def appendTextToLastUserInput(offsetOrPromptStr, strToAppend)
    endOfPrevLine = offsetOrPromptStr.is_a?(Integer) ? offsetOrPromptStr : getFormattedPromptStr(offsetOrPromptStr).clearColor.length
    print @cursor.prev_line + @cursor.forward(endOfPrevLine)
    print strToAppend
    print @cursor.next_line
  end

  def handleLambdaInput(m, wasEmptyInput)
    lambdaHelpStr    = "Please start with number I.e 42 -> r {r + 1}"
    lastPromptStrLen = getFormattedPromptStr(promptStr).clearColor.length
    @ppCaller        = :lambda


    case @ppState
      when :start
        if m[1].empty? and @lastInput.nil?
          puts "Missing input to lambda." + lambdaHelpStr
          @ppCaller = :user
          return false
        end
      when :lastWasLambdaInput
        if m[1].empty?
          puts "Can't use nested lambdas. " + lambdaHelpStr
          return false
        end
    end

    unless m[1].empty?
      pp(promptStr, m[1])
    end

    lambdaResult = nil

    begin
      lambdaResult = eval(m[2]).call(@lastInput)
    rescue SyntaxError, NameError => boom
      puts "Input lambda doesn't compile: \n" + boom.to_s
      @ppCaller = :user
      return false
    rescue StandardError => bang
      puts "Error running input lambda: \n" + bang.to_s
      @ppCaller = :user
      return false
    end

    if pp(promptStr: promptStr, trumpUserInput: lambdaResult)
      @lastLambdaInput = m[2]
      case @ppState
        when :start
          appendTextToLastUserInput(lastPromptStrLen + m[0].length, " = " + result.to_s.green)
        when :lastWasLambdaInput
          if m[1].empty?
            appendTextToLastUserInput(promptStr, (wasEmptyInput ? '' : ' = ') + result.to_s.green)
          else
            appendTextToLastUserInput(lastPromptStrLen + m[0].length, " = " + result.to_s.green)
          end
        when :auto
          appendTextToLastUserInput(promptStr, (wasEmptyInput ? '' : ' = ') + result.to_s.green)
      end
    else
      return false
    end
    @ppState  = :lastWasLambdaInput
    @ppCaller = :user
    return true

  end

  def pp(promptStr: @promptStr, trumpUserInput: nil)

    @didBranch = false
    defAns = ""

    if @ppState == :lastWasLambdaInput
      defAns = @lastLambdaInput
    end 

    userInput = trumpUserInput.nil? ? @cli.prompt(promtMsg: getFormattedPromptStr(promptStr), defaultAnswer: defAns) : trumpUserInput.to_s  
    # puts "userinput = #{userInput}"
    # puts "@ppCaller = #{@ppCaller}"
    wasEmptyInput = userInput.empty?
    wasOk         = true

    if @ppState == :lastWasLambdaInput and userInput.match(/(\d*)(\s?lambda\s?{.*}\s|\s?->.*{.*})/)
      wasEmptyInput = true
    end 

    if wasEmptyInput
      if @ppState == :lastWasLambdaInput
        userInput = @lastLambdaInput
      else
        appendTextToLastUserInput(promptStr, @lastInput.to_s.green)
        userInput = @lastInput.to_s
      end
      @ppState = :auto
    end

    if @branchCond.call(userInput)
      @lastInput = userInput
      @didBranch = true
    elsif (m = userInput.match(/(\d*)(\s?lambda\s?{.*}\s|\s?->.*{.*})/))
      if handleLambdaInput(m, wasEmptyInput) # Must return here else pp state is overwritten further down
         # @cli.saveInputStr 
         return true 
      end 
      return false
    elsif @checkValidInput.(userInput)
      @lastInput = @inputConverter_lambda.(userInput)
      @ppCaller = :user
    elsif userInput == "b"
      wasOk = :back
    elsif userInput == "h"
      wasOk = :help
      # elsif userInput == "r" #TODO
      #   wasOk = :autoRun
    else
      puts @errorMsg
      wasOk = false
    end

    if @ppCaller == :user
      @ppState = :start


      # handleLambdaInput 
    end

    @cli.saveInputStr if wasOk and trumpUserInput.nil? and not userInput == "b" and not userInput == "h"

    return wasOk

  end

  def autoRun
    pp(trumpUserInput: @lastInput)
  end

  def setDefault(defaultValue)
    @lastInput = defaultValue
  end

  def self.printHelp
    table = TTY::Table.new header: ['Input', 'Description'], alignment: [:center]
    table << ['h', {value: 'This help box', alignment: :left}]
    table << ['b', {value: 'Go back', alignment: :left}]
    table << ['↑', {value: 'History up (old values)', alignment: :left}]
    table << ['↓', {value: 'History down (newer values)', alignment: :left}]
    navStr = table.render(:unicode, alignment: [:center])
    puts "Navigation:".bold
    puts navStr

  end

  def runPrompt
    promptToRun = self
    until promptToRun.nil?
      case promptToRun.pp
        when true
          if promptToRun.nextPrompt.empty?
            return
          end
          promptToRun.nextPrompt.each do |branchTree|
            condition, branchTo = branchTree.first
            if condition.call(promptToRun.result)
              branchTo << promptToRun
              promptToRun = branchTo
              break
            end
          end
        when :back
          promptToRun = promptToRun.prevPrompt
        when :help
          UserPrompter.printHelp
        when :autoRun
          #TODO
          # promptToRun = promptToRun.prevPrompt
      end
    end
  end

  def printBranchTree
    prompter = self
    until prompter.nil?
      puts "I'm " + @promptStr
      prompter.nextPrompt.each do |branchTree|
        condition, branchTo = branchTree.first
        prompter            = branchTo
      end
    end
  end

  def tree?

  end

  def clear
    @lastInput = nil
  end

  def result
    @lastInput
  end

  def firstLink
    @prevPrompt.nil? ? self : @prevPrompt.firstLink
  end

  def <<(other)
    @prevPrompt = other
    self
  end

  def >>(other)
    if other.is_a?(Hash)
      #Change last
      @branchCond = other.first.first
      @nextPrompt.unshift ({other.first.first => other.first.last.firstLink})
      other.first.last << self
    else
      @nextPrompt << ({-> res {true} => other})
      other << self
    end
  end

end