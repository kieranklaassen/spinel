# A loop's test that reads a String's length behind a guard does not read it
# when the guard says no: the length was read once ahead of the loop, where a
# nil raised NoMethodError the guard was written to prevent.
def pick(k)
  k > 0 ? "abc" : nil
end

def count_and(s)
  i = 0
  while s && i < s.length
    i += 1
  end
  i
end

def count_not_nil(s)
  i = 0
  while !s.nil? && i < s.length
    i += 1
  end
  i
end

def count_until(s)
  i = 0
  until s.nil? || i >= s.size
    i += 1
  end
  i
end

def count_ternary(s)
  i = 0
  while (s ? i < s.length : false)
    i += 1
  end
  i
end

def count_bound(s)
  i = 0
  while i < (s ? s.length : 0)
    i += 1
  end
  i
end

def count_modifier(s)
  i = 0
  while (i < s.length if s)
    i += 1
  end
  i
end

def count_safe(s)
  i = 0
  while (k = s&.length) && i < k
    i += 1
  end
  i
end

def count_flag(s, ok)
  i = 0
  while ok && i < s.length
    i += 1
  end
  i
end

def count_three(s)
  i = 0
  while i < 9 && s && i < s.length
    i += 1
  end
  i
end

[0, 1].each do |k|
  s = pick(k)
  p [count_and(s), count_not_nil(s), count_until(s), count_ternary(s), count_bound(s),
     count_modifier(s), count_safe(s), count_flag(s, k > 0), count_three(s)]
end

# the read on the right of `||` comes after two passes: Ruby runs them first
s = pick(0)
i = 0
begin
  while i < 2 || i < s.length
    puts "pass #{i}"
    i += 1
  end
rescue NoMethodError
  puts "raised at #{i}"
end

# an operand with an effect runs ahead of the read
i = 0
begin
  while (i += 1) < s.length
  end
rescue NoMethodError
  puts "raised at #{i}"
end

# the test never reaches the read
i = 5
while i < 3 && i < s.length
  i += 1
end
p i

# a read the first test does make stays read once: these are right before and after
t = "hello world"
i = 0
n = 0
while i < t.length && t.getbyte(i) != 32
  n += 1
  i += 1
end
p [i, n]
i = 0
while i + 1 < t.size
  i += 2
end
p i
