# A class with a send of its own does not take Object#send from the rest
# of the program: a computed name on a receiver of another class still
# calls the method it names.

class Mailer
  def initialize(tag) = @tag = tag
  def send(msg, flags) = "#{@tag}:#{msg}:#{flags}"
end

class Plain
  attr_reader :log
  def initialize(n) = (@n = n; @log = [])
  def hello(k) = (@log << k; "hello #{@n} #{k}")
  def bye = "bye #{@n}"
  def mix(a, b = "d") = "#{a}#{b}"
  def on_open = "opened #{@n}"
  def on_close = "closed #{@n}"
  def fire(ev) = send("on_#{ev}")
  def twice(m) = [send(m, 2), __send__(:bye), public_send(m, 3)]
end

names = [:hello, :mix]
c = Plain.new(1)
p c.send(names[0], 0)
p c.send(names[1], 4)
p c.__send__(names[0], 5)
p c.public_send(names[1], 6, "e")
p c.fire("open")
p c.fire("close")
p c.twice(:hello)
p c.log

# builtin receivers
ops = [:sort, :reverse, :size]
ops.each { |op| p [3, 1, 2].send(op) }
m = [:upcase, :reverse][ARGV.size]
p "abc".send(m)
p 7.__send__([:succ, :pred][ARGV.size])

# a splatted argument list carries the name
a = [:hello, 9]
p c.send(*a)

# the class's own send is still the one called on its own instances
u = Mailer.new(:u)
vx = "x" + ARGV.size.to_s
puts u.send(vx, 1)
puts u.send(names[0], 2)
