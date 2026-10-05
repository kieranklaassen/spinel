# A String method that changes nothing still answers a new String, as CRuby
# does: an append to the answer leaves the receiver alone, and the answer of
# a frozen receiver is not frozen.
def report(name, s, t)
  frozen = t.frozen?
  same = t.equal?(s)
  n = s.size
  t << "!" unless frozen
  puts "#{name}: same=#{same} frozen=#{frozen} receiver #{n} -> #{s.size} answer #{t.size}"
end

# a mutable receiver, long enough that an append grows it in place
s = +"abc"
s << "d" * 100
h = { "Z" => "Y" }
report "sub string",        s, s.sub("Z", "Y")
report "sub regexp",        s, s.sub(/Z/, "Y")
report "sub string hash",   s, s.sub("Z", h)
report "sub regexp hash",   s, s.sub(/Z/, h)
report "gsub string hash",  s, s.gsub("Z", h)
report "center",            s, s.center(1)
report "center pad",        s, s.center(1, "*")
report "ljust",             s, s.ljust(1)
report "ljust pad",         s, s.ljust(1, "*")
report "rjust",             s, s.rjust(1)
report "rjust pad",         s, s.rjust(1, "*")
report "encode",            s, s.encode
report "encode UTF-8",      s, s.encode("UTF-8")
report "partition",         s, s.partition("Z")[0]
report "rpartition",        s, s.rpartition("Z")[2]
report "rpartition regexp", s, s.rpartition(/Z/)[2]

# a frozen receiver
f = "lit"
report "frozen sub string",        f, f.sub("Z", "Y")
report "frozen sub regexp",        f, f.sub(/Z/, "Y")
report "frozen sub string hash",   f, f.sub("Z", h)
report "frozen sub regexp hash",   f, f.sub(/Z/, h)
report "frozen gsub string hash",  f, f.gsub("Z", h)
report "frozen center",            f, f.center(3)
report "frozen center pad",        f, f.center(3, "*")
report "frozen ljust",             f, f.ljust(3)
report "frozen ljust pad",         f, f.ljust(3, "*")
report "frozen rjust",             f, f.rjust(3)
report "frozen rjust pad",         f, f.rjust(3, "*")
report "frozen encode",            f, f.encode
report "frozen encode UTF-8",      f, f.encode("UTF-8")
report "frozen partition",         f, f.partition("Z")[0]
report "frozen rpartition",        f, f.rpartition("Z")[2]
report "frozen rpartition regexp", f, f.rpartition(/Z/)[2]

# the answer is the caller's own: the forms a program writes
title = "name".center(2)
title << "!"
p title
out = "line".sub(/^#/, "")
out << "\n"
p out

# a method that does change something answers as before
p s.sub("abc", "x").size, "ab".center(6), "ab".ljust(4, "*"), "ab".rjust(4, "*")
p "a-b".partition("-"), "a-b".rpartition("-")

# sub!, gsub! through a Hash and slice! change their receiver where it is:
# with nothing to change it stays the String another name holds
$b = +"abc"
$b << "d" * 100
kept = $b
$b.sub!("Z", "Y")
$b.sub!(/Z/, "Y")
$b.gsub!("Z", h)
$b.slice!("Z")
p $b.sub!(/b/, "b").equal?($b)
$b << "!"
p kept.size, kept.equal?($b)
