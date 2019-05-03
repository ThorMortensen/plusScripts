require 'tty'
require 'io/console'
require 'fileutils'
require_relative 'rubyHelpers'

class Caret

  def reset
    @i = @offset
    @state = :APPEND
    @str = ""
  end

  def initialize promptStr = ""
    @cur = TTY::Cursor
    @offset = promptStr.clearColor.length + 1
    @pstr = promptStr
    reset
    # print "@i #{@i} totalLength #{totalLength}"
  end

  def totalLength
    @str.length + @offset
  end

  def strI
    @i - @offset
  end

  def moveForword amount = 1
    if (@i) == totalLength
      @state = :APPEND
      return false
    end
    @i += 1
    print @cur.column(@i)
    return true
  end

  def moveBackwards amount = 1
    @state = :INSERT
    if (@i) == @offset
      return
    end
    @i -= 1
    print @cur.column(@i)
  end

  def clearLine
    print @cur.clear_line
    print @pstr
  end

  def goHome
    @state = :INSERT unless @str.empty?
    print @cur.column(@offset)
  end

  def removeForward
    if @i < totalLength
      @str[strI] = ''
      write
    end
  end

  def removeBackward
    if @i > @offset
      @str[strI - 1] = ''
      @i -= 1
      write
    end
  end

  def pp
    print @str
    print @cur.column(@i)
  end

  def goEol
    @i = totalLength
    print @cur.column(@i)
  end

  def showSuggestion suggestion
    clearLine
    unless suggestion.nil?
      print suggestion.gray.dim
      print @cur.column(@offset)
    end
    pp
  end

  def setStr str
    @i = @offset + str.length
    @str = str
    write
  end

  def getStr
    @str
  end

  def empty?
    @str.empty?
  end

  def addChars chars = ""
    unless chars.empty?
      @i += chars.length
      case @state
      when :APPEND
        @str << chars
      when :INSERT
        @str.insert(strI - 1, chars)
      end
    end
  end

  def write chars = ""
    addChars
    clearLine
    pp
  end

  def dbgPrint
    puts
    puts @i.to_s + "\n"
    print @str
    print @cur.column(@i)
  end

end


class Manduca

  attr_accessor :inputStr

  FUNC_KEYS = {
    68  => :LEFT,
    65  => :UP,
    67  => :RIGHT,
    66  => :DOWN,
    126 => :DEL,
    51  => :DEL_PRE,
    70  => :END,
    72  => :HOME,
  }

  SPECIAL_KEYS = {
    9   => :TAB,
    3   => :SIGINT,
    127 => :BACK_SPACE,
    13  => :ENTER
  }

  def initialize promtMsg: "", defaultAnswer: "", historyFilePath: "~/.manduca-history", historyFileName: ".inputHistory" , sigIntCallback: method(:exitPoint)
    @car           = Caret.new promtMsg
    @defaultAnswer = defaultAnswer
    @history       = []
    @historyFilePath = historyFilePath
    @historyFileName = historyFileName
    @completeHistoryilePath = "#{@historyFilePath}/#{@historyFileName}"
    loadHistory
    @exit         = sigIntCallback
    reset
  end

  def reset
    @inputStr = ""
    @car.reset
    @keyCodeState  = :NONE
    @promptRunning = false
    @suggestion    = nil
    @suggestionKandidate = 0
    @suggestionBlock = ""
    @lastSuggestion = ""

    if @defaultAnswer.empty?
      puts "fuck"
      @car.write
    else
      @suggestionKandidate = @defaultAnswer
      suggestInput suggestDefault: true
    end

  end

  def prompt
    reset
    @promptRunning = true
    while @promptRunning
      STDIN.raw!
      c = STDIN.getc
      STDIN.cooked!
      parseInput c
      # printKeyCode c # For debugging
    end
    @inputStr = @car.getStr
  end

  def saveInputStr
    unless @car.getStr.nil? or @car.getStr.length <= 0
      @history.delete "#{@car.getStr}\n"
      @history.unshift "#{@car.getStr}" #unless @lastSuggestion == @car.getStr
    end
    saveHistory
  end

  private

  def exitPoint
    exit 0
  end

  def loadHistory
    return unless File.exists?(@historyFilePath)
    @history =  File.readlines(@completeHistoryilePath)
  end

  def saveHistory
    FileUtils.mkdir_p @historyFilePath
    File.open(@completeHistoryilePath, "w") { |f| f.puts(@history[0..10000]) }
  end

  def suggestInput useSuggestion: false, lockSuggestion: false, suggestDefault: false
    if useSuggestion
      @car.setStr @suggestion.clone unless @suggestion.nil?
    else
      if not @car.empty? and not lockSuggestion
        # '^'           --> Start of line to only get words starting with the input
        # Regexp.quote  --> Automatically escape any potential escape correctors
        @suggestionBlock = @history.grep(Regexp.new('^' + Regexp.quote("#{@car.getStr}"), Regexp::IGNORECASE))
      end
      unless suggestDefault
        @suggestion = @suggestionBlock[@suggestionKandidate]
        @suggestion = @suggestion.strip unless @suggestion.nil?
        @lastSuggestion = @suggestion
      else
        @suggestion = @suggestionKandidate
        puts "here"
      end
      @car.showSuggestion @suggestion
    end
  end

  def parseInput(c)
    kc = c.ord

    case @keyCodeState
    when :NONE
      if kc == 27
        @keyCodeState = :FUNC_KEY_START
        return nil
      end
    when :FUNC_KEY_START
      if kc == 91
        @keyCodeState = :FUNC_KEY_SPLIT
      end
      return nil
    when :FUNC_KEY_SPLIT
      @keyCodeState = :NONE
      case FUNC_KEYS[kc]
      when :UP

        if @car.empty?
          @suggestionBlock = @history.clone
          suggestInput
          @suggestionKandidate = (@suggestionKandidate + 1) %  @suggestionBlock.size
        else
          return if @suggestionBlock.size <= 0
          @suggestionKandidate = (@suggestionKandidate + 1) %  @suggestionBlock.size
          suggestInput
        end

      when :DOWN
        return if @suggestionBlock.size <= 0
        @suggestionKandidate = (@suggestionKandidate - 1) %  @suggestionBlock.size
        suggestInput
      when :LEFT
        @car.moveBackwards
      when :RIGHT
        unless  @car.moveForword
          unless @suggestion.nil?
            c = @suggestion[@car.strI]
            unless c.nil?
              @car.addChars c
              suggestInput lockSuggestion: true
            end
          end
        end

      when :DEL_PRE
        @keyCodeState = :DEL_PRE
      when :HOME
        @car.goHome
      when :END
        @car.goEol
      end
      return nil
    when :DEL_PRE
      @keyCodeState = :NONE
      case FUNC_KEYS[kc]
      when :DEL
        @car.removeForward
        suggestInput
      end
      return nil
    else
      return nil
    end

    case SPECIAL_KEYS[kc]
    when :TAB
      suggestInput useSuggestion: true
      return nil
    when :BACK_SPACE
      @car.removeBackward
      suggestInput

      return nil
    when :ENTER
      @promptRunning = false
      return nil
    when :SIGINT
      @exit.call
    end

    @suggestionKandidate = 0
    @car.addChars c
    suggestInput

  end

  def printKeyCode(c)
    puts "#{c} -> #{c.ord}"
  end

end

cli = Manduca.new(promtMsg: "Please write here --> ".green.bold, defaultAnswer: "This is default!", historyFileName: "manduca-test" )


answ = "foo"
while answ != "q"
  answ = cli.prompt
  puts
  puts "result was: |#{cli.inputStr}|"
  cli.saveInputStr unless answ == "q"
end
