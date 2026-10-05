# spinel: int64 -- holds a Bignum
# `when Integer` and `in Integer` beside a boxed subject tested the tag of an
# Integer that fits and no other, so a Bignum in the box fell to the next arm
# or to else. `is_a?(Integer)`, `Integer === v` and `when Numeric` already
# took it.
def kind(v)
  case v
  when Float then :float
  when Integer then :integer
  when Numeric then :numeric
  else :other
  end
end

def bump(v)
  case v
  when String, Integer then v + v
  else 0
  end
end

def pat(v)
  case v
  in Integer => n then n - 1
  in String then :string
  else :other
  end
end

def pair(v)
  case v
  in [Integer => a, Integer => b] then a + b
  in {n: Integer => n} then n * 2
  else :other
  end
end

big = [2**70, :a][0]
p kind(big), kind(-(2**70)), kind(7), kind(1.5), kind(:a)
p bump(big), bump(7), bump("s"), bump(nil)
p pat(big), pat(7), pat("s"), pat(nil)
p pair([big, 1]), pair({n: big}), pair([1, 2]), pair([1, :a])
case big
when Integer then puts "statement: integer"
else puts "statement: other"
end
x = case big when Symbol then :symbol when Integer then :integer else :other end
p x
p (Integer === big), big.is_a?(Integer)
