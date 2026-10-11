# --share-strings: a String Range keeps the Strings its ends were made from,
# so a change in place to one shows through it. `===` of a Range a variable
# holds runs its argument first and reads the Range after it; a Struct
# member's Range is read first, and its ends again once the argument is
# there. Either way an end the argument's own call changes is compared as
# that call left it.
def grow(s, v)
  s << "c"
  v
end

Hold = Struct.new(:r)
h = {"u" => "aa".dup, "n" => 1}
h["u"] << "b"
z = "a".dup
z << "d"
a = "a".dup
a << "a"
r = (a..z)
p r === h["u"], r === grow(a, h["u"]), r === h["u"]
b = "a".dup
b << "a"
st = Hold.new((b..z))
p st.r === h["u"], st.r === grow(b, h["u"]), st.r === h["u"]
