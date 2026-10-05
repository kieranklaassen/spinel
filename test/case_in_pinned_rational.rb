# spinel: int64 -- holds a Bignum
# A pinned Rational or Complex (`in ^y`) was compared with C's `==` on the
# struct, which did not build. A Rational beside a number, and two Complex,
# are compared by value, as a pinned Array, Hash or Bignum is.
def pin(x, y)
  case x
  in ^y then "hit"
  else "miss"
  end
end

half = Rational(1, 2)
puts pin(half, Rational(1, 2))
puts pin(half, Rational(1, 3))
puts pin(Rational(2, 4), 0.5r)

# a Rational beside a Float, an Integer and a Bignum, either way round
def rat_flt(x, y)
  case x
  in ^y then "hit"
  else "miss"
  end
end

def flt_rat(x, y)
  case x
  in ^y then "hit"
  else "miss"
  end
end

def rat_int(x, y)
  case x
  in ^y then "hit"
  else "miss"
  end
end

def int_rat(x, y)
  case x
  in ^y then "hit"
  else "miss"
  end
end

puts rat_flt(half, 0.5), rat_flt(half, 0.25)
puts flt_rat(0.5, half), flt_rat(0.75, half)
puts rat_int(Rational(2, 1), 2), rat_int(half, 2)
puts int_rat(2, Rational(2, 1)), int_rat(2, half)
big = 2**70
case half
in ^big then puts "hit"
else puts "miss"
end

# two Complex
def cpx(x, y)
  case x
  in ^y then "hit"
  else "miss"
  end
end

puts cpx(Complex(1, 2), Complex(1, 2))
puts cpx(Complex(1, 2), Complex(1, 3))
puts cpx(Complex(0, 2), 2i)

# a pinned expression, and the case as a value
x = Rational(3, 4)
v = case x
    in ^(Rational(1, 2) + Rational(1, 4)) then :sum
    else :other
    end
p v
