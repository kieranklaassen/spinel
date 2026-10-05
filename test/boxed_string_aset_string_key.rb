# `recv[key] = val` on a boxed receiver that holds a String, the key a String:
# the first occurrence is replaced, as on a String the compiler knows.

def local_hit
  b = [+"abcabc", 1][0]
  b["bc"] = "x"
  b
end
p local_hit

def local_value
  b = [+"abc", 1][0]
  r = (b["b"] = "xy")
  [r, b]
end
p local_value

def local_empty_key
  b = [+"abc", 1][0]
  b[""] = "x"
  b
end
p local_empty_key

def local_miss
  b = [+"abc", 1][0]
  b["zz"] = "x"
  b
rescue IndexError => e
  e.message
end
p local_miss

def frozen_hit
  b = ["abc", 1][0]
  b["b"] = "x"
  b
rescue FrozenError => e
  e.message
end
p frozen_hit

# a key that is not there is reported ahead of the frozen receiver
def frozen_miss
  b = ["abc", 1][0]
  b["zz"] = "x"
  b
rescue IndexError => e
  e.message
end
p frozen_miss

def boxed_key
  b = [+"abc", 1][0]
  k = ["c", 2][0]
  b[k] = "x"
  i = [0, "a"][0]
  b[i] = "yy"
  b
end
p boxed_key

def boxed_key_miss
  b = [+"abc", 1][0]
  k = ["zz", 2][0]
  b[k] = "x"
  b
rescue IndexError => e
  e.message
end
p boxed_key_miss

def element
  a = [+"abc", 1]
  a[0]["b"] = "x"
  k = ["c", 2][0]
  a[0][k] = "yy"
  a
end
p element

# the element is its own new contents
def element_self
  a = [+"abc", 1]
  a[0]["b"] = a[0]
  a
end
p element_self

class Holder
  def initialize
    @b = [+"abc", 1][0]
  end

  def set(k, v)
    @b[k] = v
    @b
  end
end
p Holder.new.set("b", "x")

def two_names
  s = +"abc"
  t = s
  t << "d"
  b = [s, 1][0]
  b["bc"] = "x" * 3
  [s, t, b]
end
p two_names

def multibyte
  b = [+"aébé", 1][0]
  b["b"] = "ü"
  b
end
p multibyte

# a Hash in the same position is stored into as before
def hash_in_box
  h = [{ "a" => 1 }, 2][0]
  h["b"] = 5
  k = ["c", 2][0]
  h[k] = 6
  [h["a"], h["b"], h["c"]]
end
p hash_in_box
