rows = []
24.times do
  rows << Array.new(2, self).map(&:to_s)
  z = "a" + rows.size.to_s
end
p rows.size
p rows.uniq
