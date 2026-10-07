# Flag-only: without the flag (as on master) the kept value is the
# receiver's own bytes, read after the long append has moved them.
# A call that changes its receiver in place answers the receiver. The rule
# makes the slot that keeps that answer the shared handle, and the write
# hands over the receiver's handle: the two names are one String, and a
# later change through the receiver shows through the kept name. Filled
# with a new String made from the bytes, the kept name stayed at what the
# call had left.

# an instance variable keeps concat's answer
class KeptConcat
  def initialize(s) = @s = s
  def go
    @r = @s.concat("x", "y")
    @s << " and forty more bytes, so that the buffer has to move, and then some more of them"
    p @r.size
    p @s.size
  end
end
KeptConcat.new(+"ab").go

# kept in one method, changed in another, read in a third
class KeptAcross
  def initialize(s) = @s = s
  def keep = @r = @s.concat("x", "y")
  def grow = @s << " and forty more bytes, so that the buffer has to move, and then some more of them"
  def show = puts(@r.size)
end
k = KeptAcross.new(+"ab")
k.keep
k.grow
k.show

# the change comes through an outer name of the String
class KeptOuter
  def initialize(s) = @s = s
  def keep = @r = @s.concat("x", "y")
  def show = p(@r)
end
x = +"ab"
k = KeptOuter.new(x)
k.keep
x << " and forty more bytes, so that the buffer has to move, and then some more of them"
k.show

# a local keeps it
class KeptLocal
  def initialize(s) = @s = s
  def go
    r = @s.concat("x", "y")
    @s << " and forty more bytes, so that the buffer has to move, and then some more of them"
    puts r.size
  end
end
KeptLocal.new(+"ab").go

# an append chain's answer
class KeptChain
  def initialize(s) = @s = s
  def go
    @r = (@s << "x" << "y")
    @s << " and forty more bytes, so that the buffer has to move, and then some more of them"
    puts @r.size
  end
end
KeptChain.new(+"ab").go

# replace's answer
class KeptReplace
  def initialize(s) = @s = s
  def go
    @r = @s.replace("wxyz")
    @s << " and forty more bytes, so that the buffer has to move, and then some more of them"
    puts @r.size
  end
end
KeptReplace.new(+"ab").go

# a local that holds the handle is the receiver
def kept_local_receiver(s)
  t = s
  t << "1"
  r = s.concat("x", "y")
  s << " and forty more bytes, so that the buffer has to move, and then some more of them"
  puts r.size
end
kept_local_receiver(+"ab")

# replace, prepend and clear of an instance variable, kept in another, with
# a change through either name afterwards
class KeptThree
  def initialize = @s = +"ab"
  def go
    @t = @s.replace("wxyz")
    @t << "!"
    p @s
    @u = @s.prepend("p")
    @s << "?"
    p @u
    @v = @s.clear
    @v << "new"
    p @s
  end
end
KeptThree.new.go
