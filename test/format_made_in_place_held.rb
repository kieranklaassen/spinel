# `fmt % args` builds two things, the format and the list of arguments.
#
# A format made where it is written (an interpolation, a call's result) was
# held by nothing while the arguments were built, and the one-element list
# a single argument goes into was held by nothing while that argument was
# built: whichever was made first could be collected by the making of the
# other.
w = 5
i = 7
ints = [3, 4]
p "%#{w}d %d|" % ints
floats = [1.5, 2.5]
p "%#{w}.1f %.1f|" % floats
strs = ["a", "b"]
p "%#{w}s %s|" % strs
mixed = [1, "x", :s]
p "%#{w}d %s %s|" % mixed
p "%#{w}d %s|" % [i, "x" + i.to_s]

# one argument
p "%#{w}d|" % i
p "%#{w}s|" % ("q" + i.to_s)
p "%5s|" % ("q" + i.to_s)
p "%-5s|" % :sym.to_s.upcase
either = [1, "two"][i & 1]
p "%#{w}s|" % either

# a call's result as the format
def fmt(w) = "%" + w.to_s + "d|"
p fmt(4) % 12
p fmt(4) % ints
p (fmt(3) + "%s|") % [i, "z" * 3]

# the format's nil check is kept
def no_format(c) = c ? "%d" : nil
begin
  no_format(false) % ints
rescue NoMethodError => e
  p e.class
end

# a format held ahead of its arguments is the String they change in place,
# and an interpolation reads its variable before an argument writes it
$fmt = +"%d"
def held = $fmt
def grow = ($fmt << "|%d"; 1)
p held % [grow, 2]
p "%#{w}d|%d" % [(w += 1), 2]
