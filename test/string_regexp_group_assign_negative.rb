# `s[re, n] = v` with a negative n counts the group back from the last one
def t(n)
  s = +"hello"
  begin
    s[/(e)(l)(l)/, n] = "X"
    p [n, s, $~ && $~[0]]
  rescue IndexError => e
    p [n, e.class, e.message, s]
  end
end
[-5, -4, -3, -2, -1].each { |n| t(n) }
def u(n, v)
  s = +"hello"
  begin
    s[/(e)(x)?(l)/, n] = v
    p [n, s]
  rescue IndexError, TypeError => e
    p [n, e.class, e.message, s]
  end
end
u(-1, "X"); u(-2, "Y"); u(-3, "Z"); u(-4, "W")
def w(n)
  s = +"hello"
  begin
    s[/(e)(x)?(l)/, n] = n.abs.to_s
    p [n, s]
  rescue IndexError => e
    p [n, e.class, e.message, s]
  end
end
w(-1); w(-2); w(-3); w(-4)
def fz(n)
  s = "hello".freeze
  begin
    s[/(e)(x)?(l)/, n] = "v"
  rescue FrozenError, IndexError => e
    p [n, e.class, e.message]
  end
end
fz(-1); fz(-2); fz(-3); fz(-4); fz(1); fz(2); fz(4)
s = +"abc"
s[/(a)(b)/, -1] = "B"
p s
s[/(a)(B)/, -2] = "A"
p s
