# --share-strings: a String Range keeps the Strings its ends were made from,
# and `when` compares a boxed String with them as they are: the plain one and
# an appended one's handle alike, also where a Struct member holds the Range.
Holder = Struct.new(:r)
a = "a".dup
a << "a"
z = "a".dup
z << "z"
x = "a".dup
x << "b"
v = [1, "a" + "b", x, "aa"]
s = Holder.new((a..z))
r = (a..z)

def hit(subject, range)
  case subject
  when range then true
  else false
  end
end

def held(subject, holder)
  case subject
  when holder.r then true
  else false
  end
end

p hit(v[1], r), hit(v[2], r), hit(v[3], r), hit(v[0], r)
p held(v[1], s), held(v[2], s), held(v[3], s), held(v[0], s)
z.replace("aa")
p hit(v[1], r), hit(v[2], r), hit(v[3], r)
p held(v[1], s), held(v[2], s), held(v[3], s)
q = case v[2]
    when s.r then true
    else false
    end
p q
z << "z"
p hit(v[2], r), held(v[2], s)

# a Range written in the `when`: one whose second end's code changes the
# first is read once that code has run, one of two locals is compared as
# it is made
def last_end(s, e)
  s << "c"
  e
end
g = "a".dup
k = "a".dup
k << "z"
w = case v[2]
    when (g..last_end(g, k)) then true
    else false
    end
y = case v[2]
    when (a..k) then true
    else false
    end
p w, y, g
