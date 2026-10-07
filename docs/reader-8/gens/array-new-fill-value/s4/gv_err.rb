s = "abc"
t = "def"
u = "xyz"
rows = []
24.times do
  begin
    raise s + t
  rescue
    rows << Array.new(2, $!).map(&:message)
  end
  z = s + u
  z = u + s
end
bad = rows.count { |r| r != rows[0] }
p rows.size
p bad
p rows[0]
