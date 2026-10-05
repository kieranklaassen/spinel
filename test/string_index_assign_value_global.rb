# The value of a String index assignment on a global, a class variable or a
# constant is the right-hand side, and the String is changed, as for a local.

$g = +"abcdef"

def global_index
  r = ($g[0] = "x")
  [r, $g]
end
p global_index

def global_start_length
  r = ($g[1, 2] = "yy")
  [r, $g]
end
p global_start_length

def global_range
  r = ($g[-2..] = "z")
  [r, $g]
end
p global_range

def global_key
  r = ($g["d"] = "w" * 2)
  [r, $g]
end
p global_key

# the last expression of a method is a value too
def global_last
  $g[0] = "q"
end
p global_last, $g

def global_as_argument
  x = [($g[-1] = "m"), 1]
  [x, $g]
end
p global_as_argument

def global_past_end
  r = ($g[40] = "x")
  [r, $g]
rescue IndexError => e
  e.message
end
p global_past_end

$f = "abc"

def global_frozen
  r = ($f[0] = "x")
  [r, $f]
rescue FrozenError => e
  e.message
end
p global_frozen

class Holder
  @@s = +"abc"

  def self.set
    r = (@@s[1] = "xy")
    [r, @@s]
  end
end
p Holder.set

NAME = +"abc"

def constant_index
  r = (NAME[-1] = "z")
  [r, NAME]
end
p constant_index
