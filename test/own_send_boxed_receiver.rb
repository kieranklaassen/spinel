# A boxed receiver that holds an instance of a class with its own #send
# calls that method, literal first argument and all; every other value in
# the same slot keeps Object#send, which calls the method the literal names.
class Conn
  def initialize(tag)
    @tag = tag
    @sent = 0
  end

  def send(msg, flags = 9)
    @sent += 1
    "#{@tag}:#{msg}:#{flags}"
  end

  def hello(k) = "Conn#hello #{k}"
  def size = 77
end

class TcpConn < Conn
end

class Plain
  def initialize(n) = @n = n
  def hello(k) = "hello #{@n} #{k}"
  def size = @n
  private def hidden(v) = "hidden #{v}"
end

class Hub
  def initialize = @conns = []
  def add(c) = @conns << c
  def hello = @conns.each { |c| puts c.send("hello", 0) }
  def all = @conns.map { |c| c.send(:hi, 1) }
end

h = Hub.new
h.add(Conn.new(:a))
h.add(TcpConn.new(:b))
h.hello
p h.all

n = 0
[Conn.new(:c), Plain.new(1), TcpConn.new(:t)].each { |o| puts o.send(:hello, (n += 1)) }
p n
[Conn.new(:d), "str", [1, 2], { a: 1 }, :sym].each { |o| p o.send(:size) }
[Conn.new(:e), nil, Plain.new(2)].each { |o| p o&.send(:hello, 3) }
[Plain.new(3), Conn.new(:f)].each { |o| p o.send(:hidden, 4) }
[Conn.new(:g), Plain.new(4)].each { |o| p o.__send__(:hello, 5) }
[Conn.new(:i), Plain.new(5)].each { |o| p o.public_send(:hello, 6) }

list = [Conn.new(:j), Plain.new(6)]
p list.shift.send(:hello, 7)
p list.shift.send(:hello, 7)
p list.size

# An Array that settles on one class with no send of its own is not boxed
# for it: its elements keep the direct call.
class Node
  attr_reader :kids

  def initialize(v)
    @v = v
    @kids = []
  end

  def total = @v + @kids.sum { |k| k.send(:total) }
end

root = Node.new(1)
root.kids << Node.new(2)
root.kids[0].kids << Node.new(3)
p root.send(:total)
