# `outer[i][key] = val` where the element is a boxed String and the key a
# String: the first occurrence is replaced and the slot holds the new
# contents, as with an Integer index.

# a String the compiler knows only as a boxed value, or a Hash
def text(i) = i == 0 ? +"abcabc" : { "b" => 1 }

def element
  a = [text(0), 1]
  a[0]["bc"] = "x"
  i = 0
  k = "c"
  a[i][k] = "yy"
  a
end
p element

def value
  a = [text(0), 1]
  r = (a[0]["b"] = "xy")
  [r, a[0]]
end
p value

# the element is its own new contents
def element_self
  a = [text(0), 1]
  a[0]["b"] = a[0]
  a
end
p element_self

def hash_value
  h = { 1 => text(0), 2 => 5 }
  h[1]["b"] = "ZZ"
  h[1][""] = "<"
  h[1]
end
p hash_value

def miss
  a = [text(0), 1]
  a[0]["zz"] = "x"
  a
rescue IndexError => e
  e.message
end
p miss

def multibyte
  a = [+"aébé", 1]
  a[0]["b"] = "ü"
  a[0]
end
p multibyte

# a Hash or an Array in the same slot is stored into as before
def other_elements
  a = [text(1), [7, 8], 2]
  a[0]["c"] = 5
  a[1][0] = 9
  [a[0]["b"], a[0]["c"], a[1]]
end
p other_elements

# the key and the value run once, in that order
def note(log, x) = (log << x; x)

def order
  log = []
  a = [text(0), text(1)]
  a[0][note(log, "b")] = note(log, "x")
  a[1][note(log, "c")] = note(log, "dd").size
  [a[0], a[1]["c"], log]
end
p order

# every round's element keeps what it was given
def rounds
  bad = 0
  300.times do |i|
    a = [text(0), i]
    a[0]["b" + ""] = "Z" + i.to_s
    h = { 1 => text(0), 2 => i }
    h[1]["b"] = "Y" + i.to_s
    bad += 1 unless a[0] == "aZ#{i}cabc" && h[1] == "aY#{i}cabc"
  end
  bad
end
p rounds
