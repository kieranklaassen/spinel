# A method that yields is spliced into its caller, so its match is written to
# the caller's registers. A program with such a method keeps the registers as
# they are left by a raise: here the miss in `raises` clears them.
def each_word(s)
  s.split.each { |w| yield w if w =~ /\w/ }
end

def raises(s)
  s =~ /nope/
  raise ArgumentError, "x"
end

each_word("a b") { |w| w }
begin
  raises("zq")
rescue ArgumentError
end
p $~
