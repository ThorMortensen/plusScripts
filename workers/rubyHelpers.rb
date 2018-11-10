#   Auther  : thm
#   Date    : 25-October-2017
#   File    : rubyHelpers.rb
#   Project : scripts

module RubyHelpers




end
class Array

  def closestTo(value)
    low, hi = [0, self.length - 1]
    while low < hi
      mid = (low + hi) / 2
      if self[mid] == value
        return self[mid]
      elsif self[mid] < value
        low = mid + 1
      else
        hi = mid
      end
    end

    return first if value < first
    if self[mid] < value
      lowClosest = self[mid]
      highClosest = self[mid+1]
      distH = highClosest - value
      distL = value - lowClosest
    else
      lowClosest = self[mid-1]
      highClosest = self[mid]
      distH = highClosest - value
      distL = value - lowClosest
    end

    return highClosest if distH == distL
    return distH < distL ? highClosest : lowClosest
  end


  def each_except(thingToExempt)
    each_except_with_index(thingToExempt) {|x|
      yield(x)
    }
  end

  def each_except_index(thingToExempt)
    each_except_with_index(thingToExempt) {|x, i|
      yield(i)
    }
  end

  def each_except_with_index(thingToExempt)
    each_with_index {|x, i|
      if thingToExempt.is_a?(Array) # Fast hack but expensive runtime. Use with care (I.e small arrays)
        next if thingToExempt.member?(x)
      else
        next if x.equal?(thingToExempt)
      end
      yield(x, i)
    }
  end

end


#@formatter:off
class String
  def white;          "\e[30m#{self}\e[0m" end
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def greenLight;     "\e[92m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end
  def yellow;         "\e[43m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_yell;        "\e[103m#{self}\e[0m"end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def dim;            "\e[2m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end

  def clearColor
    gsub(/(#{"\e"}\[\d*m)/n, '')
  end

  def is_integer?
    self.to_i.to_s == self
  end 

  def is_hex?
    self.match(/0x([a-fA-F0-9]+)/)
  end 
end
#@formatter:on

#
# class UserPrompter
#   def installing_missing_gems(&block)
#     yield
#   rescue LoadError => e
#     gem_name = e.message.split('--').last.strip
#     install_command = 'gem install ' + gem_name
#
#     # install missing gem
#     puts 'Probably missing gem: ' + gem_name
#     print 'Auto-install it? [yN] '
#     gets.strip =~ /y/i or exit(1)
#     system(install_command) or exit(1)
#
#     # retry
#     Gem.clear_paths
#     puts 'Trying again ...'
#     require gem_name
#     retry
#   end
#
#   installing_missing_gems do
#     require 'tty-cursor'
#   end
#
#   # @param [String] promtStr
#   def initialize(promtStr, acceptedInput_lambda = -> input {input.match(/\d/)}, errorMsg = 'Must be a number')
#     @pormtStr = promtStr
#     @checkValidInput = acceptedInput_lambda
#     @cursor = TTY::Cursor
#     @errorMsg = errorMsg
#     @lastInput = nil
#   end
#
#   def promt(promtStr = @pormtStr)
#     while true
#       print "#{promtStr}#{@lastInput.nil? ? '' : @lastInput.to_s.gray} "
#       print @cursor.backward(@lastInput.to_s.length + 1)
#       system("stty raw -echo") #=> Raw mode, no echo
#       userInput = STDIN.getc
#       system("stty -raw echo") #=> Reset terminal mode
#       if userInput != "\r"
#         print @cursor.clear_line_before
#         print userInput
#         userInput += STDIN.gets.chomp
#         if @checkValidInput.(userInput)
#           return @lastInput = userInput
#         else
#           puts @errorMsg
#         end
#       end
#     end
#   end
#   def clear
#     @lastInput = nil
#   end

# end