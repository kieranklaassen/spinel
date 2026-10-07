# `s[range] = v` with the Range's start outside the String is RangeError,
# naming the Range: a start below the String was counted from the end twice
# and wrote into it.

def below_start
  s = +"abc"
  s[-5..1] = "x"
  s
rescue RangeError => e
  e.message
end
p below_start

def below_start_value
  s = +"abc"
  r = (s[-5...-4] = "x")
  [r, s]
rescue RangeError => e
  e.message
end
p below_start_value

def below_start_endless
  s = +"abc"
  s[-5..] = "x"
  s
rescue RangeError => e
  e.message
end
p below_start_endless

def at_start
  s = +"abc"
  s[-3..1] = "x"
  s
end
p at_start

def past_end
  s = +"abc"
  s[4..5] = "x"
  s
rescue RangeError => e
  e.message
end
p past_end

def at_end
  s = +"abc"
  s[3..5] = "x"
  s
end
p at_end

def two_names
  s = +"abc"
  t = s
  t << "d"
  s[-6..1] = "x"
  [s, t]
rescue RangeError => e
  e.message
end
p two_names

def range_in_a_variable(r)
  s = +"aébé"
  s[r] = "x"
  s
rescue RangeError => e
  e.message
end
p range_in_a_variable(-5..1)
p range_in_a_variable(-4..1)

# the Range is checked ahead of the frozen receiver
def frozen_below_start
  s = "abc"
  s[-5..1] = "x"
  s
rescue RangeError => e
  e.message
end
p frozen_below_start

def frozen_in_range
  s = "abc"
  s[1..2] = "x"
  s
rescue FrozenError => e
  e.message
end
p frozen_in_range

def boxed_below_start
  b = [+"abc", 1][0]
  b[-5..1] = "x"
  b
rescue RangeError => e
  e.message
end
p boxed_below_start

def boxed_past_end
  b = [+"abc", 1][0]
  b[4..5] = "x"
  b
rescue RangeError => e
  e.message
end
p boxed_past_end

def boxed_in_range
  b = [+"abc", 1][0]
  b[-3..1] = "x"
  b[2..] = "yz"
  b
end
p boxed_in_range

def element_below_start
  a = [+"abc", 1]
  a[0][-5..1] = "x"
  a
rescue RangeError => e
  e.message
end
p element_below_start

# the value is read before the Range is found outside
$log = []
def logged(x)
  $log << x
  x
end

def value_before_the_bound
  s = +"abc"
  s[4..5] = logged("x")
  s
rescue RangeError
  $log
end
p value_before_the_bound
