# A class's own #send is the method a call reaches on its instances, also
# when the first argument is a literal Symbol or String: it is the message,
# not the name of a method. A receiver of another class keeps Object#send,
# and __send__ still reaches a method by name on the class with its own send.
class Conn
  attr_reader :out
  def initialize(tag)
    @tag = tag
    @out = []
  end

  def send(msg, flags)
    @out << [msg, flags]
    "#{@tag}:#{msg}:#{flags}"
  end

  def twice(msg) = [send(msg, 1), send(:again, 2)]
end

class TcpConn < Conn
end

module Posting
  def public_send(to) = "posted to #{to}"
end

class Mailer
  include Posting
  def self.send(what, n) = "class #{what} #{n}"
end

Frame = Struct.new(:tag) do
  def send(msg) = "#{tag}<#{msg}>"
end

class Calc
  def double(n) = n * 2
end

class Hub
  attr_reader :conn
  def initialize(conn) = @conn = conn
  def hello = @conn.send(:hello, 3)
end

def make = Conn.new(:made)

KEPT = Conn.new(:kept)

c = Conn.new(:a)
puts c.send("hello", 0)
puts c.send(:bye, 1)
p c.out
p c.twice(:hey)
puts c&.send(:nav, 4)
puts TcpConn.new(:tcp).send(:hello, 5)
puts Hub.new(Conn.new(:ivar)).hello
puts Hub.new(Conn.new(:reader)).conn.send(:hello, 6)
puts make.send(:hello, 7)
puts KEPT.send(:hello, 8)
puts Mailer.new.public_send(:kieran)
puts Mailer.send(:hello, 9)
puts Frame.new(:f).send(:hello)
puts c.public_send(:send, :through, 10)
p c.__send__(:out).size
puts Calc.new.send(:double, 21)
