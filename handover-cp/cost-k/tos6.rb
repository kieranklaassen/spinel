class Q
  def to_s = "q"
end
q = Q.new
row = [5, "s"]
v = row[0]
n = 0
i = 0
while i < 200000
  v.to_s
  n += 1
  i += 1
end
q.to_s
p n
