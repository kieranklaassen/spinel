# Appended to a String with `<<`, the parts of an interpolation run in order
# too. This program changes Strings in place, so only parts that are not
# Strings move: a String part read in its place would miss a later change.
$log = []
def lg(i) = ($log << i; i)
class K
  def initialize = @name = +"n"
  def f(a) = ($log << [:f, a]; a * 2)
  def two(a, b) = a * 10 + b
  def name = @name
  def rename = (@name << "x"; 1)
end
k = K.new
buf = +""
buf << "#{k.f(lg(1))}-#{k.f(lg(2))}"
p buf, $log
# a String part that a later part changes in place is read after the change
s = +"s"
t = "#{s}#{k.two((s << "x").size, lg(3))}"
u = "#{k.name}#{k.two(k.rename, lg(4))}"
p t, u
