require 'tty'
require 'io/console'

class Manduca

  attr_reader :inputStr

  ARROW_KEYS = {68 => :LEFT, 65 => :UP, 67 => :RIGHT, 66 => :DOWN}

  def initialize
    @cur          = TTY::Cursor
    @inputStr     = ""
    @keyCodeState = :NONE
    @i            = 0
    @inputState   = :APPEND

  end

  def prompt
    c = 'f'
    i = 0
    while c != 'q'
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
      case @inputState
        when :APPEND
          @inputStr << c
          print c
        when :INSERT
          i = @i+1
          @inputStr.insert(i, c)
          print @cur.clear_line
          print @inputStr
          print @cur.column(i)
      end
      @i += 1
    end

    def navigateInput(c)
      kc = c.ord

      case @keyCodeState
        when :NONE
          if kc == 27
            @keyCodeState = :ARROW_KEY?
            return nil
          end
        when :ARROW_KEY?
          if kc == 91
            @keyCodeState = :ARROW_KEY
            return nil
          end
        when :ARROW_KEY
          @keyCodeState = :NONE
          case ARROW_KEYS[kc]
            when :UP
            when :DOWN
            when :LEFT
              if @i > 0
                print @cur.backward
                @i          -= 1
                @inputState = :INSERT
              end
            when :RIGHT
              if @i < @inputStr.length
                print @cur.forward
                @i          += 1
                @inputState = :INSERT
              else
                @inputState = :APPEND
              end
          end
          return nil

        else
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












