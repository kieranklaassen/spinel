# A boxed String times a Float in a program with a `*` of its own. A boxed
# `*` reaches no String's own `*`, so the builtin's repeat must not answer
# where the program's method was meant: the TypeError stays.

class String
  def *(o)
    raise TypeError, "an Integer count, please" unless o.is_a?(Integer)
    "#{self}x#{o}"
  end
end

puts "ab" * 3

row = ["ab", 7]
cnt = [2.5, :k]
begin
  p row[0] * cnt[0]
rescue TypeError => e
  puts e.class
end
