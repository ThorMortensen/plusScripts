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

  def initialize(ipAddress = nil, port = 8881)
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

    def sendPackage
      @socket.write("dispInf")
    end

    def getRes
      @res = @socket.readline
      puts "Res is --> #{@res}"
      return @res
    end

end

f = CmdHandler.new "192.168.52.48"

f.connect
f.sendPackage
while f.getRes == "Init done\n" || f.getRes == "Stopping\n"
end 

f.close

