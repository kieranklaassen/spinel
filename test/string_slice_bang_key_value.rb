# s.slice!(key) with a String key answers the removed part as a String of its
# own, not the key: it can be changed, and changing it leaves the key alone.

def literal_key
  s = +"abcd"
  r = s.slice!("bc")
  r << "x"
  [r, s]
end
p literal_key

def key_that_can_change
  s = +"abcd"
  k = +"bc"
  r = s.slice!(k)
  r.setbyte(0, 90)
  r << " and forty more bytes, so that the buffer has to move"
  [r, k, s, r.equal?(k)]
end
p key_that_can_change

def no_match
  s = +"abcd"
  r = s.slice!("zz")
  [r, s]
end
p no_match

def as_an_argument
  s = +"aébé"
  a = [s.slice!("é"), s.slice!("é")]
  a[0] << "!"
  [a, s]
end
p as_an_argument

def two_names
  s = +"abcd"
  t = s
  t << "e"
  r = s.slice!("cd")
  r << "!"
  [r, s, t]
end
p two_names

# A receiver that is a call runs once, hit or miss, with its value taken or
# not.
$made = 0
def made
  $made += 1
  +"abcb"
end

def receiver_is_a_call
  r = made.slice!("b")
  r << "x"
  made.slice!("b")
  miss = made.slice!("zz")
  [r, miss, $made]
end
p receiver_is_a_call
