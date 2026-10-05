# spinel: int64 -- holds a Bignum
# `when` beside a Rational or a Complex compared the two with C's `==` on the
# struct, which did not build, and a Rational literal arm (`when 0.5r`) read
# its subject as an Integer and missed a Rational or a Float that equals it.
# A Rational beside a number, and two Complex, are compared by value.
def rat(x)
  case x
  when Rational(1, 3) then :third
  when Rational(1, 2) then :half
  when 2 then :two
  when 0.25 then :quarter
  else :other
  end
end
p rat(Rational(1, 2)), rat(Rational(1, 3)), rat(Rational(2, 1)), rat(Rational(1, 4)), rat(Rational(5, 7))

# a number beside a Rational arm
def flt(x)
  case x
  when Rational(1, 2) then :half
  when Rational(2, 1), Rational(3, 1) then :whole
  else :other
  end
end
p flt(0.5), flt(2.0), flt(3.0), flt(0.3)

def int(x)
  case x
  when Rational(1, 2) then :half
  when Rational(2, 1) then :two
  else :other
  end
end
p int(2), int(3)

# the literal arm
def lit(x)
  case x
  when 0.5r then :half
  when 2r then :two
  else :other
  end
end
p lit(Rational(1, 2)), lit(Rational(2, 1)), lit(Rational(1, 3))

def lit_f(x)
  case x
  when 0.5r then :half
  when 2r then :two
  else :other
  end
end
p lit_f(0.5), lit_f(2.0), lit_f(0.3)

def lit_i(x)
  case x
  when 0.5r then :half
  when 2r then :two
  else :other
  end
end
p lit_i(2), lit_i(3)

# two Complex
def cpx(x)
  case x
  when Complex(1, 3) then :a
  when Complex(1, 2), 2i then :b
  else :other
  end
end
p cpx(Complex(1, 2)), cpx(Complex(1, 3)), cpx(Complex(0, 2)), cpx(Complex(5, 5))

# as a value, an arm held in a local, a Bignum arm
x = Rational(1, 2)
y = Rational(1, 2)
v = case x when y then :hit else :miss end
p v
big = 2**70
p(case x when big then :hit else :miss end)
