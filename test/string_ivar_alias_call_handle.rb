# `@r = @s.clear`, `@r = @s.replace(x)` and `@r = @s.prepend(x)` between
# two instance variables that hold String handles: the call hands the
# handle on, a change through either name shows through the other, and
# the assignment is left as it is.

class Cleared
  def initialize(s) = @s = s
  def go
    @r = @s.clear
    @r << "!"
    p @s, @r
  end
end
Cleared.new(+"abcd").go

class Replaced
  def initialize
    a = +"abcd"
    @s = a
    a << "0"
  end
  def go
    [1].each do
      @r = @s.replace("wxyz")
      @r << "!"
      @s << " and forty more bytes, so that the buffer has to move, and then some more of them"
      p @s, @r
    end
  end
end
Replaced.new.go

class Prepended
  def initialize(s)
    @s = s
    s << "0"
  end
  def keep
    @r = @s.prepend("x")
  end
  def go
    keep
    @r << " and forty more bytes, so that the buffer has to move, and then some more of them"
    p @s, @r
  end
end
Prepended.new(+"abcd").go

class Twice
  def initialize(s) = @s = s
  def go
    @r = (@s).replace("wxyz")
    [1].each { @r << "!" }
    p @s, @r
  end
end
k = Twice.new(+"abcd")
k.go
k.go
