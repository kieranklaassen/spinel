# A boxed String or Array times a Float in a program that aliases `*`. The
# alias makes `*` another method of the builtin class (here `+`), which a
# boxed `*` does not reach: the repeat must not answer for it, and the
# TypeError stays.

class String
  alias * +
end
class Array
  alias * +
end

row = ["ab", [1, 2], 7]
cnt = [2.5, :k]
begin
  p row[0] * cnt[0]
rescue TypeError => e
  puts e.message
end
begin
  p row[1] * cnt[0]
rescue TypeError => e
  puts e.message
end
