# A `return` in a proc returns from the lambda the proc was made in, as it
# returns from a method. The lambda's body had no home for it: at the top
# level the proc's `return` ended the script, and in a method it only left
# the proc.
f = lambda { pr = proc { return 7 }; pr.call; 8 }
p [f.call, 9]

def in_method
  f = ->(a) { pr = Proc.new { return a * 2 }; pr.call; 8 }
  [f.call(4), f.(5), 9]
end
p in_method

puts "the value's class is the proc's, not the tail's"
g = lambda { |k| pr = proc { return "str" }; pr.call if k; 8 }
p g.call(false), g.call(true)
g = lambda { |k| pr = proc { return 2.5 }; pr.call if k; nil }
p g.call(false), g.call(true)
g = lambda { |k| pr = proc { return }; pr.call if k; [1] }
p g.call(false), g.call(true)
g = lambda { |k| pr = proc { return 1, k }; pr.call if k; :tail }
p g.call(false), g.call(true)

puts "through a method, a block and the lambda's own ensure"
def pass(pr, v) = [1].each { pr.call(v) }
def each_twice
  yield 1
  yield 2
end
seen = []
h = lambda do |v|
  begin
    each_twice do |e|
      seen << e
      pr = proc { |q| return q.to_s * e }
      pass(pr, v) if v > 0
    end
    :tail
  ensure
    seen << :ensure
  end
end
p h.call(21), h.call(0), seen

puts "each call is its own home"
r = lambda do |n|
  pr = proc { return n * 10 }
  if n > 0
    puts "inner answered #{r.call(n - 1)}"
  end
  pr.call
  :not_reached
end
p r.call(2)
depth = 0
o = lambda do |pr0|
  depth += 1
  if pr0
    pr0.call
    :inner_not_reached
  else
    pr = proc { return :outer }
    o.call(pr)
    :outer_not_reached
  end
end
p o.call(nil), depth

puts "a nested lambda, a lambda that outlives its method"
n = lambda do
  inner = lambda { pr = proc { return 1 }; pr.call; 2 }
  mine = proc { return [inner.call, :n] }
  via = lambda { mine.call; :via }
  [via.call, 3]
end
p n.call
def make(k) = lambda { |a| pr = proc { return a + k }; pr.call; 8 }
m = make(100)
p m.call(1), [1, 2].map(&m)

puts "next, return and catch in the lambda keep their meaning"
x = lambda do |a|
  pr = proc { return :proc }
  next :next if a == 0
  return :return if a == 1
  c = catch(:t) do
    pr.call if a == 2
    throw :t, :thrown
  end
  [c, :tail]
end
p x.call(0), x.call(1), x.call(2), x.call(3)

puts "a proc that outlives its lambda"
keep = []
e = lambda { |boom| keep << proc { return 7 }; raise "boom" if boom; keep.size }
p e.call(false)
begin
  e.call(true)
rescue => err
  puts err.message
end
keep.each do |pr|
  begin
    pr.call
    puts "no raise"
  rescue LocalJumpError => err
    puts "LocalJumpError: #{err.message}"
  end
end

puts "many calls, a captured String"
buf = +"ab"
s = lambda do |i|
  pr = proc { buf << "!"; return "v#{i}" + buf }
  pr.call if i.odd?
  [i, buf.size]
end
acc = []
60.times { |i| acc << s.call(i) }
p acc[0], acc[1], acc[58], acc[59], buf.size
