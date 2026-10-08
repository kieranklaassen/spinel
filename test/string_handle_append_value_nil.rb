# An append that is the value of its body is emitted by its own arm, with no
# nil test. On a String held as a handle (two appends in a row) that the
# program set to nil, it appended nothing and then read the NULL handle. It
# raises NoMethodError, as the same append does as a statement.

def appended(clear)
  t = +""
  t << "a"
  t << "b"
  t = nil if clear
  t << "c"
end

def in_arm(clear, n)
  t = +""
  t << "a"
  t << "b"
  t = nil if clear
  if n > 0
    t << "c"
  else
    t << "d"
  end
end

def by_lambda(clear)
  t = +""
  t << "a"
  t << "b"
  t = nil if clear
  f = -> { t << "c" }
  f.call
end

def as_statement(clear)
  t = +""
  t << "a"
  t << "b"
  t = nil if clear
  t << "c"
  t
end

def raised
  yield
rescue NoMethodError => e
  e.class
end

p appended(false)
p raised { appended(true) }
p in_arm(false, 1)
p in_arm(false, 0)
p raised { in_arm(true, 1) }
p raised { in_arm(true, 0) }
p by_lambda(false)
p raised { by_lambda(true) }
p as_statement(false)
p raised { as_statement(true) }

# the value is the String itself
s = appended(false)
s << "!"
p s
