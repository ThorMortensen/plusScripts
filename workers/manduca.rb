require 'tty'
require 'io/console'
require 'fileutils'
require_relative 'rubyHelpers'


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

  def initialize(promtMsg: "", sigIntCallback: method(:exitPoint))
    @cur           = TTY::Cursor
    @history       = []
    @historyFilePath = ".inputHistory"
    @historyFileName = "manduca-history"
    @completeHistoryilePath = "#{@historyFilePath}/#{@historyFileName}"
    loadHistory
    @exit         = sigIntCallback
    reset
    @promtMsg = promtMsg
  end

  def reset
    @inputStr      = ""
    @keyCodeState  = :NONE
    @i             = 1
    @inputState    = :APPEND
    @promptRunning = false
    @suggestion    = nil
    @suggestionKandidate = 0
    @suggestionBlock = ""
    @lastSuggestion = ""  
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
    return @inputStr
  end

  def saveInputStr
    unless @inputStr.nil? or @inputStr.length <= 0
      @history.delete "#{@inputStr}\n"
      @history.unshift "#{@inputStr}" #unless @lastSuggestion == @inputStr
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

    def printInput useSugestion: false, lockSuggestion: false
      print @cur.clear_line
      print @promtMsg
      if useSugestion
        @inputStr = @suggestion.clone unless @suggestion.nil?
        @i        = @inputStr.length + 1
      else

        if not @inputStr.empty? and not lockSuggestion
          # '^'           --> Start of line to only get words starting with the input
          # Regexp.quote  --> Automatically escape any potential escape correctors
          @suggestionBlock = @history.grep(Regexp.new('^' + Regexp.quote("#{@inputStr}"), Regexp::IGNORECASE)) 
        end 
        @suggestion = @suggestionBlock[@suggestionKandidate]
        @suggestion = @suggestion.strip unless @suggestion.nil?
        @lastSuggestion = @suggestion
        print @suggestion.gray.dim unless @suggestion.nil?
        print @cur.column(0)
      end
      print @inputStr
      print @cur.column(@i)

    end

    def dbgPrint
      puts
      puts @i.to_s + "\n"
      print @inputStr
      print @cur.column(@i)
    end

    def moveCurser i

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
              if inputStr.empty?
                @suggestionBlock = @history.clone
                printInput
                @suggestionKandidate = (@suggestionKandidate + 1) %  @suggestionBlock.size
              else 
                return if @suggestionBlock.size <= 0
                @suggestionKandidate = (@suggestionKandidate + 1) %  @suggestionBlock.size
                printInput
              end 
            when :DOWN
              return if @suggestionBlock.size <= 0
              @suggestionKandidate = (@suggestionKandidate - 1) %  @suggestionBlock.size
              printInput
            when :LEFT
              if @i > 1
                print @cur.backward
                @i          -= 1
                @inputState = :INSERT
              end
            when :RIGHT
              if @i < @inputStr.length + 1
                print @cur.forward
                @i          += 1
                @inputState = :INSERT
              else

                unless @suggestion.nil?

                  c = @suggestion[@i - 1]
                  unless c.nil?
                    @i += 1
                    @inputStr << c
                    printInput lockSuggestion: true
                  end
                end
                @inputState = :APPEND
              end
            when :DEL_PRE
              @keyCodeState = :DEL_PRE
            when :HOME
              @i = 1
              print @cur.column(@i)
              @inputState = :INSERT if @inputStr.length > 0
            when :END
              @i = @inputStr.length + 1
              print @cur.column(@i)
          end
          return nil
        when :DEL_PRE
          @keyCodeState = :NONE
          case FUNC_KEYS[kc]
            when :DEL
              if @i < @inputStr.length + 1
                @inputStr[@i - 1] = ''
                printInput
              end
          end
          return nil
        else
          return nil
      end

      case SPECIAL_KEYS[kc]
        when :TAB
          printInput useSugestion: true
          return nil
        when :BACK_SPACE
          if @i > 1
            @inputStr[@i - 2] = ''
            @i                -= 1
            printInput
          end
          return nil
        when :ENTER
          @promptRunning = false
          return nil
        when :SIGINT
          @exit.call 
      end

      @suggestionKandidate = 0
      @i += 1
      case @inputState
        when :APPEND
          @inputStr << c
        when :INSERT
          @inputStr.insert(@i - 2, c)
      end

      printInput

    end

    def printKeyCode(c)
      puts "#{c} -> #{c.ord}"
    end

end

cli = Manduca.new(promtMsg: "")


answ = "foo"
while answ != "q"
  answ = cli.prompt
  puts
  puts "result was: |#{cli.inputStr}|"
  cli.saveInputStr unless answ == "q"
end 
