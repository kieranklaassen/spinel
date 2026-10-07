# The statement form of `when *list`: a list that is not of the subject's
# own kind is asked element by element, as the value form asks it.
list = [1..3, String, :q]
case 2
when *list then puts "2 in"
else puts "2 out"
end
case 9
when *list then puts "9 in"
else puts "9 out"
end
case "x"
when *list then puts "x in"
else puts "x out"
end
case :q
when *list then puts "q in"
else puts "q out"
end
case 2.5
when *list then puts "2.5 in"
else puts "2.5 out"
end

# an Integer list beside a Float subject compares numbers, not truncations
ints = [1, 2]
case 2.5
when *ints then puts "2.5 among ints"
else puts "2.5 not among ints"
end
case 2.0
when *ints then puts "2.0 among ints"
else puts "2.0 not among ints"
end

# a list of another kind than the subject is no match, and builds
names = ["a", "b"]
case 1
when *names then puts "1 in"
else puts "1 out"
end
case "b"
when *ints then puts "b in"
else puts "b out"
end

# the subject is evaluated once
n = 0
mixed = [String, 5..9]
case (n += 1)
when *mixed then puts "one in"
else puts "one out"
end
puts n

# a splat beside plain arms, and two splats
case 7
when :zz, *mixed then puts "7 in"
else puts "7 out"
end
case "s"
when *ints, *mixed then puts "s in"
else puts "s out"
end

# the typed search is kept for a list of the subject's own kind
case 2
when *ints then puts "2 in"
else puts "2 out"
end
case "b"
when *names then puts "b in"
else puts "b out"
end
case 3
when *[1.5, 3.0] then puts "3 in"
else puts "3 out"
end
