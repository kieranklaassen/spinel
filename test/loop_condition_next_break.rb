# A `next` or a `break` written in the condition of a `while` or `until` is
# that loop's own: `next` tests the condition again, `break` leaves the loop,
# with its value when the loop is used as one. Neither belongs to a loop or a
# block around it.
i = 0
while (i += 1; next if i < 3; false)
end
p i

i = 0
until (i += 1; next if i < 3; true)
end
p i

i = 0
n = 0
n += 1 while (i += 1; next if i.odd?; i < 6)
p [i, n]

i = 0
n = 0
while (i += 1; next if i.odd?; i < 6)
  n += 1
  next if n == 1
  n += 100
end
p [i, n]

i = 0
n = 0
while (i += 1; break if i == 4; true)
  n += 10
end
p [i, n]

# the body runs once more only when the condition says so
i = 0
n = 0
begin
  n += 10
end while (i += 1; next if i < 3; i < 5)
p [i, n]

i = 0
n = 0
begin
  n += 10
end while (i += 1; break if i == 3; true)
p [i, n]

i = 0
n = 0
begin
  n += 10
  next if n < 30
  n += 1
end until (i += 1; next if i < 3; i > 4)
p [i, n]

i = 0
n = 0
begin
  n += 10
end until (i += 1; break if i == 3; false)
p [i, n]

# inside another loop, a block and a method
j = 0
while j < 2
  j += 1
  i = 0
  while (i += 1; next if i < 3; false)
  end
  k = 0
  while (k += 1; break if k == 3; true)
  end
  puts "i #{i} k #{k} j #{j}"
end

r = [1, 2, 3].map do |x|
  i = 0
  while (i += 1; next if i < x; false)
  end
  i * 10
end
p r

p [1, 2, 3].count { |x| j = 0; while (j += 1; next if j < x; false); end; j == 2 }

def lim(n)
  i = 0
  while (i += 1; break if i == n; true)
  end
  i
end
p lim(4)

# a loop used as a value
i = 0
x = while (i += 1; break i * 2 if i == 3; true)
end
p x
i = 0
y = while (i += 1; break if i == 2; true)
end
p y
k = 0
z = (k += 1 while (break :early if k == 2; k < 5))
p [k, z]
p [1, 2].map { |v| q = while (break v * 10 if v == 2; false); end; q }
