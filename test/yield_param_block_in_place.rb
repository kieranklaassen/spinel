# A yielding method is spliced at its call site. A String parameter its
# body only reads or hands on takes the argument's value where something
# can assign the variable while the body runs. By value it missed what
# the call's block did to that String in place: `show(u) { u << "x"; u =
# +"k" if done }` showed "u", and so did `show(@s) { @s << "x" }`, whose
# block assigns nothing. Where the block changes the String in place the
# parameter is an alias again: one each store in the block's text moves
# off the variable first, so it keeps the String it was given, or a plain
# one where no store can run during the call.

def show(w)
  yield
  p w
  nil
end

def size_of(z) = z.size

def hand_on(w)
  yield
  p size_of(w), w
  nil
end

def show_each(w)
  [1, 2].each { yield }
  p w
  nil
end

def bump(s) = s << "!"

# the block appends, and assigns on a path that does not run
u = +"u"
show(u) { u << "x"; u = +"k" if u.size > 9 }
p u

# appends, then assigns: the parameter keeps the String with the append
u = +"u"
show(u) { u << "x"; u = +"k" }
p u

# assigns, then appends to the new String
u = +"u"
show(u) { u = +"k"; u << "x" }
p u

# other changes in place: a bang method, replace, an index store, concat,
# an append through a method
u = +"u"
show(u) { u.upcase!; u = +"k" if u.size > 9 }
u = +"u"
show(u) { u.replace("zz"); u = +"k" if u.size > 9 }
u = +"u"
show(u) { u[0] = "X"; u = +"k" if u.size > 9 }
u = +"u"
show(u) { u.concat("y"); u = +"k" if u.size > 9 }
u = +"u"
show(u) { bump(u); u = +"k" if u.size > 9 }

# a multiple assignment moves the alias as well
u = +"u"
show(u) { u << "x"; u, _t = +"k", 1; u << "z" }
p u

# the parameter handed on, the yield inside the method's own iterator
u = +"u"
hand_on(u) { u << "x"; u = +"k" if u.size > 9 }
u = +"u"
show_each(u) { u << "x"; u = +"k" if u.size > 9 }

# the block runs twice; the store sits in a builtin iterator's block
def twice(w)
  yield
  yield
  p w
  nil
end
u = +"u"
twice(u) { u << "x"; u = +"k" }
p u
u = +"u"
show(u) { [1, 2].each { u << "x"; u = +"k" if u.size > 2 } }
p u

# a proc elsewhere assigns the variable; nothing the call runs can call it
q = +"q"
pr = proc { q = +"k" }
show(q) { q << "x" }
pr.call
p q

# in a method
def run
  s = +"s"
  show(s) { s << "x"; s = +"k" if s.size > 9 }
  show(s) { s << "y"; s = +"k" }
  p s
end
run

# an instance variable: the block only appends; appends and assigns;
# appends beside a call on an Array; calls a method of self that appends
class Holder
  def initialize
    @s = +"a"
    @n = [1]
  end
  def add_x = @s << "x"
  def count = @n.size
  def go
    show(@s) { @s << "x" }
    show(@s) { @s << "y"; @s = +"b" if @s.size > 9 }
    show(@s) { @s << "z"; @s = +"b" }
    p @s
    show(@s) { @s = +"c"; @s << "x" }
    p @s
    show(@s) { @n.push(2); @s << count.to_s }
    show(@s) { add_x; add_x }
    hand_on(@s) { @s << "#{count}" }
  end
  # a method of the class that reads the parameter through a top-level one
  def size_shown(w)
    yield
    p size_of(w)
    nil
  end
  def sized
    size_shown(@s) { @s << "!" }
  end
end
h = Holder.new
h.go
h.sized
