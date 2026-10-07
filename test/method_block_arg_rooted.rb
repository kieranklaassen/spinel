# A Method made in place and handed over as a block (`run(x, &method(:g))`)
# becomes a proc whose allocation can collect; the Method lives through it.
def g(t) = t + 1
def bang(t) = (t << "!")
def run(x) = yield(x)
def kr(x, &b) = b.call(x)

class Acc
  def initialize(k) = @k = k
  def add(t) = t + @k
  def tag(t) = "#{t}:#{@k}"
  def each_one(x) = yield(x)
  def go(x) = each_one(x, &method(:add))
end

# a method of the top level
p run(1, &method(:g))
f = +"f"
run(f, &method(:bang))
p f

# a method of an object made in place, and of self
p run(2, &Acc.new(5).method(:add))
p run("s", &Acc.new(7).method(:tag))
p Acc.new(9).go(1)

# many of them, each with Strings made around it
sum = 0
names = []
20.times do |i|
  names << "n#{i}"
  sum += run(i, &Acc.new(i).method(:add))
end
p sum, names.size

# already right: a Method held in a local, an explicit to_proc, a block parameter
m = method(:g)
p run(8, &m), run(7, &method(:g).to_proc), kr(3, &method(:g))
p [1, 2, 3].map(&method(:g))
