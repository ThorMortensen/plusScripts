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

class UserPrompter

  attr_reader :promptStr, :checkValidInput, :errorMsg, :inputConverter_lambda, :nextPrompt, :prevPrompt, :didBranch


  @controlKeys = {'r' => :autoRun, 'b' => :back, 'h' => :help, 'q' => :quit}
  @@sigExitMsg = "Exiting."

  def self.setSignalExitMsg (msg)
    @@sigExitMsg = msg
  end


  # @param [String] promptStr
  def initialize(promptStr, acceptedInput_lambda = -> input {input.is_integer?}, errorMsg = 'Must be (or produce) a number', inputConverter_lambda = -> input {input.to_i})
    @nextPrompt      = []
    @cursor          = TTY::Cursor
    @reader          = TTY::Reader.new(interrupt: -> {puts @@sigExitMsg; exit(1)})
    @branchCond      = -> res {false}
    @lastLambdaInput = nil
    @ppState         = :start
    @ppCaller        = :user
    @didBranch       = false


    @promptStr = promptStr
    if acceptedInput_lambda.is_a?(UserPrompter) # Clone rest of the parameters from any incoming objects of the same type
      @checkValidInput       = acceptedInput_lambda.checkValidInput
      @errorMsg              = acceptedInput_lambda.errorMsg
      @inputConverter_lambda = acceptedInput_lambda.inputConverter_lambda
    else
      @checkValidInput = acceptedInput_lambda
      if errorMsg.is_a?(UserPrompter)
        @errorMsg              = errorMsg.errorMsg
        @inputConverter_lambda = errorMsg.inputConverter_lambda
      else
        @errorMsg = errorMsg
        if inputConverter_lambda.is_a?(UserPrompter)
          @inputConverter_lambda = inputConverter_lambda.inputConverter_lambda
        else
          @inputConverter_lambda = inputConverter_lambda
        end
      end
    end
  end

  def getFormattedPromptStr(promptStr)
    "#{promptStr}#{
    (@lastInput.nil? and @lastLambdaInput.nil?) ?
        '' :
        '(' + (((@ppCaller == :lambda or @ppState == :lastWasLambdaInput) ? @lastLambdaInput.to_s + " = " : '') + @lastInput.to_s).gray.dim + ')'} ~> "
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

    if pp(promptStr, lambdaResult)
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

  def pp(promptStr = @promptStr, trumpUserInput = nil)

    @didBranch = false

    userInput = trumpUserInput.nil? ? @reader.read_line(getFormattedPromptStr(promptStr)) : trumpUserInput.to_s
    userInput.chomp!
    wasEmptyInput = userInput.empty?
    wasOk         = true

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
      return handleLambdaInput(m, wasEmptyInput) # Must return here else pp state is overwritten further down
    elsif @checkValidInput.(userInput)
      @lastInput = @inputConverter_lambda.(userInput)
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
    end

    return wasOk

  end

  def autoRun
    pp(trumpUserInput = @lastInput)
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
      @nextPrompt.prepend ({other.first.first => other.first.last.firstLink})
      other.first.last << self
    else
      @nextPrompt << ({-> res {true} => other})
      other << self
    end
  end

end