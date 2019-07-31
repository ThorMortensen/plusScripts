#!/usr/bin/env ruby

# Date 8-Jun-2017
# Author Thor Mortensen, THM (THM@rovsing.dk)


require 'socket'


class RawSocket

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
    @socket.write("pyro64")
  end

  def getRes
    @res = @socket.readline
    puts "Res is --> #{@res}"
    return @res
  end

end

f = RawSocket.new "192.168.52.39"

f.connect
f.sendPackage
while f.getRes == "Init done\n" || f.getRes == "Stopping\n"
end

f.close

