require 'tty'
require 'io/console'
require 'fileutils'
require_relative 'rubyHelpers'


class Manduca

  attr_reader :inputStr

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
      127 => :BACK_SPACE,
      13  => :ENTER
  }

  def initialize
    @cur           = TTY::Cursor
    @inputStr      = ""
    @keyCodeState  = :NONE
    @i             = 1
    @inputState    = :APPEND
    @promptRunning = false
    @suggestion    = nil
    @suggestKandidate = 0
    @suggestBlock = nil
    @history       = []
    @historyFilePath = ".inputHistory"
    @historyFileName = "alphabetic.mda"
    @completeHistoryilePath = "#{@historyFilePath}/#{@historyFileName}"

  end

  def prompt
    loadHistory
    c              = 'f'
    @promptRunning = true
    while @promptRunning
      STDIN.raw!
      c = STDIN.getc
      STDIN.cooked!
      parseInput(c)
      # printKeyCode c

    end
  end

  def test
    saveHistory
  end 

  private

    def loadHistory 
      return unless File.exists?(@historyFilePath)

      @history =  File.readlines(@completeHistoryilePath)

    end 

    def saveHistory 

      th = [    "abbacies",
        "abbacomes",
        "Abbadide",
        "Abbai",
        "abbaye",
        "abbandono",
        "abbas",
        "abbasi",
        "Abbasid",
        "abbassi",
        "Abbassid",
        "Abbasside",
        "Abbate",
        "overcapitalised",
        "overcapitalising",
        "overcapitalization",
        "overcapitalize",
        "over-capitalize",
        "overcapitalized",
        "overcapitalizes",
        "overcapitalizing",
        "overcaptious",
        "overcaptiously",
    ]

      FileUtils.mkdir_p @historyFilePath
      File.open(@completeHistoryilePath, "w") { |f| f.puts(th) }
        

    end 

    def printInput useSugestion = false
      print @cur.clear_line
      return if @inputStr.empty?
      if useSugestion
        @inputStr = @suggestion.clone
        @i        = @inputStr.length + 1
      else
        @suggestBlock = @history.grep(/#{@inputStr}/i)
        @suggestion = @suggestBlock[@suggestKandidate]
        @suggestion = @suggestion.strip unless  @suggestion.nil?
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
              return if @suggestBlock.nil?
              @suggestKandidate = (@suggestKandidate + 1) %  @suggestBlock.size
              printInput
            when :DOWN
              return if @suggestBlock.nil?
              @suggestKandidate = (@suggestKandidate - 1) %  @suggestBlock.size
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
                    printInput
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
      end

      @suggestKandidate = 0
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

cli = Manduca.new

cli.prompt
puts
puts "result was: |#{cli.inputStr}|"

