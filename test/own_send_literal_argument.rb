# A class's own #send is the method a call reaches on its instances, also
# when the first argument is a literal Symbol or String: it is the message,
# not the name of a method.

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

  def twice(msg) = [send(msg, 1), send(:again, 2), self.send("self", 3)]
end

class TcpConn < Conn
end

module Posting
  def send(to) = "posted to #{to}"
end

class Mailer
  include Posting
end

class Feed
  def self.send(what, n) = "class #{what} #{n}"
end

Frame = Struct.new(:tag) do
  def send(msg) = "#{tag}<#{msg}>"
end

class Calc
  def double(n) = n * 2
end

c = Conn.new(:a)
puts c.send("hello", 0)
puts c.send(:bye, 1)
p c.out
p c.twice(:hey)
puts c&.send(:nav, 4)
puts Conn.new(:new).send(:hello, 5)
puts TcpConn.new(:tcp).send(:hello, 6)
puts Mailer.new.send(:kieran)
puts Feed.send(:hello, 7)
puts Frame.new(:f).send(:hello)
[1, 2].each { |i| puts c.send(:each, i) }
puts c.public_send(:send, :through, 8)
p c.__send__(:out).size

# a receiver that may be nil has Kernel's send, and nil has no such method
n = ARGV.size > 5 ? Conn.new(:n) : nil
p((n.send(:out) rescue "nil has no out"))

# a class with no send of its own keeps Object#send
puts Calc.new.send(:double, 21)

# a class reopened after the call has not given its instances the name yet
class Late
  def hi = "hi"
end
p Late.new.send(:hi)
class Late
  def send(msg) = "late #{msg}"
end
p Late.new.send(:hi)

# nor has a class whose body runs the call ahead of its def, or whose def
# an `if` did not reach
class Early
  def hi = "hi"
  def run = send(:hi)
  FIRST = new.run
  def send(msg) = "early #{msg}"
end
p Early::FIRST
class Maybe
  def hi = "hi"
end
if ARGV.size > 5
  class Maybe
    def send(msg) = "maybe #{msg}"
  end
end
p Maybe.new.send(:hi)
