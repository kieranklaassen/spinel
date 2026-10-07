class Q
  def then = self
end
q = Q.new
row = [5, q]
v = row[0]
i = 0
while i < 200_000
  v.then
  i += 1
end
puts "done"
