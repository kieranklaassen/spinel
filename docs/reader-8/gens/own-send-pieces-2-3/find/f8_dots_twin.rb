class Own
  def zend(msg, *rest, **kw, &b) = "own:#{msg}:#{rest.size}:#{kw.size}:#{b ? b.call(5) : 'nb'}"
end
class Plain
  def one(a = 0, k: 1) = "Plain#one #{a} #{k} #{block_given? ? yield(3) : 'nb'}"
  def uno(a = 0, k: 1) = "Plain#uno #{a} #{k} #{block_given? ? yield(3) : 'nb'}"
end
def relay(...) = $t.send(...)
m = [:one, :uno][ARGV.size]
$t = Plain.new
p relay(m, 1)
