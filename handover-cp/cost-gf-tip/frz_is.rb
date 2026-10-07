class K
  def frozen? = true
end
k = K.new
p k.frozen?
row = [5, "q"]
n = 0
i = 0
while i < 3_000_000
  x = row[i % 2]
  n += 1 if x.frozen?
  i += 1
end
p n
