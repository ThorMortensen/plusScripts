require 'tty'
require 'io/console'

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
      72  => :HOME
  }

  SPECIAL_KEYS = {
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

    @history = [
        "abbacies",
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

  end

  def prompt
    c              = 'f'
    @promptRunning = true
    while @promptRunning
      STDIN.raw!
      c = STDIN.getc
      STDIN.cooked!
      addInput(navigateInput(c))
      # printKeyCode c

    end
  end


  private

    def addInput(c)
      return if c.nil?
      @i += 1

      case @inputState
        when :APPEND
          @inputStr << c
          suggestion = @history.grep(/#{@inputStr}/).first
          print @cur.clear_line
          print suggestion
          print @cur.column(@i)

        when :INSERT
          @inputStr.insert(@i - 2, c)
          print @cur.clear_line
          print @inputStr
          print @cur.column(@i)
      end
    end

    def dbgPrint
      puts
      puts @i.to_s + "\n"
      print @inputStr
      print @cur.column(@i)
    end

    def navigateInput(c)
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
            when :DOWN
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
                print @cur.clear_line
                print @inputStr
                print @cur.column(@i)
              end
          end
          return nil
        else
          return nil
      end


      case SPECIAL_KEYS[kc]
        when :BACK_SPACE
          if @i > 1
            @inputStr[@i - 2] = ''
            @i                -= 1
            print @cur.clear_line
            print @inputStr
            print @cur.column(@i)
          end
          return nil
        when :ENTER
          @promptRunning = false
          return nil
      end

      return c

    end

    def printKeyCode(c)
      puts "#{c} -> #{c.ord}"
    end


end

cli = Manduca.new


cli.prompt
puts
puts "result was: " + cli.inputStr









