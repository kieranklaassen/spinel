# A String Range written in a `when` with two ends made on the spot: the
# begin is held by its temp alone while the end is made.
def mk(n) = n.to_s

n = 0
200.times do |i|
  s = (i + 1).to_s
  case s
  when i.to_s..(i + 3).to_s then n += 1
  end
end
p n

# a subject made on the spot, and an excluded end
n = 0
200.times do |i|
  case (i + 1).to_s
  when "#{i}"...mk(i + 3) then n += 1
  else n += 1000
  end
end
p n

# the value of the case
n = 0
200.times do |i|
  n += case mk(i + 1)
       when mk(i)..mk(i + 3) then 1
       else 0
       end
end
p n

# a second Range in the same `when`, and a later arm
n = 0
200.times do |i|
  s = (i + 1).to_s
  case s
  when "zz".."zzz", ("" + i.to_s).."#{i + 3}" then n += 1
  when i.to_s..(i + 3).to_s then n += 1000
  end
end
p n

# inside a method
def pick(i, s)
  case s
  when i.to_s..(i + 3).to_s then 1
  else 0
  end
end
n = 0
200.times { |i| n += pick(i, (i + 1).to_s) }
p n

# one end a local: nothing to keep
n = 0
lo = "5"
200.times do |i|
  case (i + 1).to_s
  when lo..(i + 3).to_s then n += 1
  when i.to_s.."zz" then n += 2
  end
end
p n
