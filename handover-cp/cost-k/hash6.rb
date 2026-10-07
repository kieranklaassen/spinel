class Q
  def hash = 7
end
q = Q.new
row = [5, "s"]
v = row[0]
n = 0
i = 0
while i < 200000
  v.hash
  n += 1
  i += 1
end
q.hash
p n
