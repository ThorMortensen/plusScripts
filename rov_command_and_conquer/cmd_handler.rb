# Date 8-Jun-2017
# Author Thor Mortensen, THM (THM@rovsing.dk)


require 'socket'

$noTTY = false
begin
  require 'tty'
rescue LoadError
  $noTTY = true
end

class CmdHandler

  def initialize(ipAddress = nil, port = 8888)
    @ip = ipAddress
    @port = port
  end

  def connect
    @socket = TCPSocket.open(@ip, @port)
    @isConnected = true
  end

  def close
    @isConnected = false
    @socket.close
  end

  def sendCmd(cmdId, arg1, arg2)
    connect unless @isConnected
    new_packet
    set_command_id cmdId
    set_packet_id 2
    set_sender_id 127
    set_arg1 arg1
    set_arg2 arg2
    sendPackage
    getRes
    close # Close as we are very slow in man mode
  end

  def print_package
    errorDescription = [
        "Successful completion".green,
        "Unknown command".red,
        "Argument 1 invalid".red,
        "Argument 2 invalid".red,
        "No such device".red,
        "Device file error".red,
    ]

    si = @res[4]
    pa = (@res[5] << 8 | @res[6])
    ci = @res[7]
    cs = @res[8]
    rv = (@res[9] << 24 | @res[10] << 16 | @res[11] << 8 | @res[12])
    ta = @res[13]

    if $noTTY
      puts
      puts "~~~~~~~~~~~~~~~~~~~~{ Package Returned }~~~~~~~~~~~~~~~~~~~~~~~~".bg_blue
      puts "+----------------+------------+--------------------------------+"
      puts "| Package fields | Return val | Description                    |"
      puts "+----------------+------------+--------------------------------+"
      puts "|  Sender ID     : #{si.to_s.center(10, ' ')} | Originator ID"
      puts "|  Packet ID     : #{pa.to_s.center(10, ' ')} | Packet count, sender does ++"
      puts "|  Cmd ID        : #{ci.to_s.center(10, ' ')} | Command number/ID sent"
      puts "|  #{"Cmd status".bold}    : #{cs == 0 ? cs.to_s.center(10, ' ').green : cs.to_s.center(10, ' ').red} | #{errorDescription[cs] || "Undefined error".red}"
      puts "|  #{"Return value".bold.blue}  : #{rv.to_s.center(10, ' ').bold.blue} | #{"Value returned".bold.blue}"
      puts "|  Tag           : #{ta.to_s.center(10, ' ')} | Tag for each packets"
      puts "+----------------+------------+--------------------------------+"
      puts
    else
      table = TTY::Table.new header: ['Package fields', 'Return val', 'Description'], alignment: [:center]
      table << [{value: "Sender ID"                  , alignment: :left} , si.to_s,                              {value: "Originator ID"                               ,alignment: :left} ]
      table << [{value: "Packet ID"                  , alignment: :left} , pa.to_s,                              {value: "Packet count, sender does ++"                ,alignment: :left} ]
      table << [{value: "Cmd ID"                     , alignment: :left} , ci.to_s,                              {value: "Command number/ID sent"                      ,alignment: :left} ]
      table << [{value: "#{"Cmd status".bold}"       , alignment: :left} , cs == 0 ? cs.to_s.green : cs.to_s.red,{value: errorDescription[cs] || "Undefined error".red ,alignment: :left} ]
      table << [{value: "#{"Return value".bold.blue}", alignment: :left} , rv.to_s.bold.blue,                    {value: "Value returned".bold.blue                    ,alignment: :left} ]
      table << [{value: "Tag"                        , alignment: :left} , ta.to_s,                              {value: "Tag for each packets"                        ,alignment: :left} ]
      puts "Package Returned:".bg_blue
      puts table.render(:unicode, alignment: [:center])
    end

  end

  private

    def sendPackage
      @socket.write(@data.map(&:to_i).pack('c*'))
    end

    def getRes
      @res = @socket.readline.bytes.to_a
    end

    def new_packet
      @data = Array.new(18)
      @data[0] = 77 # 'M'
      @data[1] = 65 # 'A'
      @data[2] = 83 # 'S'
      @data[3] = 67 # 'C'

      @data[17] = 0x0A
    end

    def set_sender_id(sid)
      @data[4] = sid
    end

    def set_packet_id(pid)
      @data[5] = (pid >> 8) & 0xFF
      @data[6] = (pid & 0xFF)
    end

    def set_command_id(cid)
      @data[7] = cid
    end

    def set_arg1(val)
      @data[8] = 1
      @data[9] = (val >> 24) & 0xFF
      @data[10] = (val >> 16) & 0xFF
      @data[11] = (val >> 8) & 0xFF
      @data[12] = (val & 0xFF)
    end

    def set_arg2(val)
      @data[8] = 2
      @data[13] = (val >> 24) & 0xFF
      @data[14] = (val >> 16) & 0xFF
      @data[15] = (val >> 8) & 0xFF
      @data[16] = (val & 0xFF)
    end


end