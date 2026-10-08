# The same with alias_method: `*` is String's `+` here, and a boxed String
# times a Float keeps its TypeError.

class String
  alias_method :*, :+
end

row = ["ab", 7]
cnt = [2.5, :k]
begin
  p row[0] * cnt[0]
rescue TypeError => e
  puts e.message
end
