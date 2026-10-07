# A program whose text the own-send proofs cannot read keeps Object#send for
# every literal send, as before: an alias of one of the three names, a def of
# one that calls a method of the program, instance_eval by any spelling, a
# module reopened, BasicObject. Any one of them decides for the whole
# program; each line below is what CRuby prints.

class Old
  def hi = "hi"
  alias_method :orig_send, :__send__
  def send(m, *a) = orig_send(m, *a)
end
p Old.new.send(:hi)

class Relay
  def hi = "hi"
  def fwd(m, *a) = __send__(m, *a)
  def public_send(m, *a) = fwd(m, *a)
end
p Relay.new.public_send(:hi)

class Calc
  def double(n) = n * 2
end
class Probe
  def send(msg, n) = "probe #{msg} #{n}"
  def double(n) = -n
  def ask(o) = o.instance_eval { send(:double, 4) }
  def ask2(o) = o.__send__(:instance_eval) { send(:double, 5) }
end
p Probe.new.ask(Calc.new)
p Probe.new.ask2(Calc.new)

module Named
  def send(m, *a) = "own:#{m}"
end
module Mixed
end
class Late
  include Mixed
  def hi = "hi"
end
p Late.new.send(:hi)
module Mixed
  include Named
end

class Bare < BasicObject
  def hi = "hi"
  def run = __send__(:hi)
end
puts Bare.new.run
