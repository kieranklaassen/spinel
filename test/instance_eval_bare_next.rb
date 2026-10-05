# A `next` or a `break` with no value leaves the block of instance_eval or
# instance_exec, and the call answers nil.

class Other
  def inspect = "#<Other>"
end

class Box
  def initialize; @v = 7; end
  def go(&b) = instance_exec(&b)
  def ev(&b) = instance_eval(&b)

  def own(c)
    t = instance_eval { next if c; @v }
    u = instance_exec(3) { |e| break if c; @v + e }
    [t, u]
  end
end

class Pt
  attr_reader :v
  def initialize(v); @v = v; end
end

# each kind of last expression, the value held in a local
def nx_int(o, c)
  t = o.instance_eval { next if c; 4 }
  t
end
def nx_str(o, c)
  t = o.instance_eval { next if c; "s" }
  t
end
def nx_sym(o, c)
  t = o.instance_eval { next if c; :a }
  t
end
def nx_bool(o, c)
  t = o.instance_eval { next if c; true }
  t
end
def nx_ary(o, c)
  t = o.instance_eval { next if c; [1, 2] }
  t
end
def nx_obj(o, c)
  t = o.instance_eval { next if c; Other.new }
  t
end
def nx_ivar(o, c)
  t = o.instance_eval { next if c; @v }
  t
end

o = Box.new
p nx_int(o, true)
p nx_int(o, false)
p nx_str(o, true)
p nx_str(o, false)
p nx_sym(o, true)
p nx_sym(o, false)
p nx_bool(o, true)
p nx_bool(o, false)
p nx_ary(o, true)
p nx_ary(o, false)
p nx_obj(o, true)
p nx_obj(o, false)
p nx_ivar(o, true)
p nx_ivar(o, false)

# a `break` leaves the same way
def br_int(o, c)
  t = o.instance_eval { break if c; 4 }
  t
end
def br_str(o, c)
  t = o.instance_eval { break if c; "s" }
  t
end
def br_sym(o, c)
  t = o.instance_eval { break if c; :a }
  t
end
def br_bool(o, c)
  t = o.instance_eval { break if c; true }
  t
end
def br_obj(o, c)
  t = o.instance_eval { break if c; Other.new }
  t
end

p br_int(o, true)
p br_int(o, false)
p br_str(o, true)
p br_str(o, false)
p br_sym(o, true)
p br_sym(o, false)
p br_bool(o, true)
p br_bool(o, false)
p br_obj(o, true)
p br_obj(o, false)

# the value used where it is written
def used(o, c)
  p [o.instance_eval { next if c; 4 }, o.instance_eval { next if c; "s" }, 1]
  p [o.instance_eval { break if c; 4 }, o.instance_eval { break if c; :a }, 1]
  p o.instance_eval { next if c; 4 }.nil?
  p o.instance_eval { break if c; "s" }.nil?
  p(o.instance_eval { next if c; 4 } || 9)
  p(o.instance_eval { break if c; "s" } || "alt")
  p "<#{o.instance_eval { next if c; 4 }}>"
  p(o.instance_eval { next if c; @v })
end

used(o, true)
used(o, false)

# instance_exec, a receiverless call, a method that forwards its block, and
# a receiver held by value
def exec(o, c)
  t = o.instance_exec(2) { |e| next if c; e + @v }
  u = o.instance_exec("x") { |e| break if c; e }
  [t, u]
end
def fwd(o, c)
  t = o.go { next if c; @v }
  u = o.ev { break if c; @v + 1 }
  [t, u]
end
def held(q, c)
  t = q.instance_eval { next if c; @v }
  t
end

p exec(o, true)
p exec(o, false)
p o.own(true)
p o.own(false)
p fwd(o, true)
p fwd(o, false)
p held(Pt.new(3), true)
p held(Pt.new(3), false)

# at the top level and in a loop: each pass starts from nil again
c = ARGV.length == 0
t = o.instance_eval { next if c; 4 }
p t
i = 0
while i < 3
  w = o.instance_eval { next if i == 1; break if i == 2; @v + i }
  p w
  i += 1
end
p [1, 2, 3].map { |x| o.instance_eval { next if x == 2; @v * x } }

# beside a `next` and a `break` that carry a value
def mixed(o, k)
  t = o.instance_eval { next if k == 1; next :n if k == 2; break "s" if k == 3; @v }
  t
end

p mixed(o, 1)
p mixed(o, 2)
p mixed(o, 3)
p mixed(o, 4)

# through an ensure, and with the value unused
def ens(o, c)
  t = o.instance_eval do
    begin
      next if c
      @v
    ensure
      puts "ens"
    end
  end
  t
end
def unused(o, c)
  o.instance_eval { puts "in"; next if c; puts "tail"; @v }
  puts "after"
end

p ens(o, true)
p ens(o, false)
unused(o, true)
unused(o, false)

# a `next` in a block nested there is that block's own
def inner(o)
  t = o.instance_eval { [1, 2].each { |x| next if x == 1 }; @v }
  t
end

p inner(o)
