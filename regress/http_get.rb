#!/usr/bin/env ruby

require_relative '../lib/http.rb'
require 'socket'

# start a simple HTTP server
ok_server_thread = Thread.new do
  socket = TCPServer.new('localhost', 4567).accept
  socket.puts ['HTTP/1.0 200 OK', 'Content-Type: text/plain',
    "Content-Length: 4", 'Connection: close',
    '', 'A-OK'].join("\r\n")
  socket.close
end

# start a simple HTTP server that breaks the connection before responding
broken_server_thread = Thread.new do
  server = TCPServer.new('localhost', 4568)
  3.times do |i|
    socket = server.accept
    if i == 2
      socket.puts ['HTTP/1.0 200 OK', 'Content-Type: text/plain',
        "Content-Length: 4", 'Connection: close',
        '', 'A-OK'].join("\r\n")
    end
    socket.close
  end
end

sleep 0.1

puts Scraper.get('http://localhost:4567/', 0)
puts Scraper.get('http://localhost:4568/', 3, 0.2)

ok_server_thread.join(1)
broken_server_thread.join(1)
