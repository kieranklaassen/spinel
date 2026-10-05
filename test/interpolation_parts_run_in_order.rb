# Each part of an interpolation runs to its end before the next part starts:
# a later part's arguments see what an earlier part's call did.
$log = []
def lg(i) = ($log << i; i)
class K
  def initialize = @n = 0
  def f(a) = ($log << [:f, a]; a * 2)
  def g(a) = ($log << [:g, a]; a.to_s)
  def two(a, b) = ($log << [a, b]; self)
  def bump = (@n += 1)
  def cur = @n
  def name = "k"
end
class R                                  # a reader over a queue of tokens
  def initialize(t) = @t = t
  def nxt = @t.shift
  def item(tok) = tok == "(" ? "[" + item(nxt) + "]".tap { nxt } : tok
end
def show = (p $log; $log = [])

k = K.new
# one call a part, each with a call for its argument
puts "#{k.f(lg(1))} #{k.g(lg(2))}"
show
# two arguments a call, three parts
s = "#{k.two(lg(1), lg(2)).nil?}/#{k.two(lg(3), lg(4)).nil?}/#{k.two(lg(5), lg(6)).name}"
p s
show
# a chain of calls in each part
s = "#{k.two(lg(1), lg(2)).two(lg(3), lg(4)).name}#{k.two(lg(5), lg(6)).two(lg(7), lg(8)).name}"
p s
show
# literal arguments: the calls themselves
p "#{k.two(1, 2).two(3, 4).nil?}/#{k.two(5, 6).two(7, 8).nil?}"
show
# the second part's argument reads what the first part's call changed
p "#{k.bump} #{k.f(k.cur)} #{k.two(k.cur, k.bump).cur}"
show
n = 0
p "#{n += 1} #{k.two(n, lg(9)).name} #{n}"
show
# a reader over tokens: each part takes its own
r = R.new(%w[( a ) b])
puts "#{r.item(r.nxt)} #{r.item(r.nxt)}"
# appended to a String, part by part
buf = +""
buf << "#{k.f(lg(1))}-#{k.g(lg(2))}"
p buf
show
# in a method, and in a block
def join3(k) = "#{k.g(lg(1))}#{k.g(lg(2))}#{k.g(lg(3))}"
p join3(k), [1, 2].map { |i| "#{k.f(lg(i))}:#{k.f(lg(i + 10))}" }
show
# one part alone, and parts with no call for an argument, are as they were
p "#{k.two(lg(1), lg(2)).name}", "#{lg(1)}/#{lg(2)}/#{k.name}"
show
