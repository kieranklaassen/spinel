Encoding.default_external = Encoding::BINARY
names = Dir["fam/*.rb"].map { |f| File.basename(f, ".rb") }.sort
rm = File.readlines("rows.m.tsv", chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a] }
rp = File.readlines("rows.p.tsv", chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a] }
cured = Hash.new(0); stay = Hash.new(0); typed = Hash.new(0)
names.each do |n|
  co = Marshal.load(File.binread("fam/#{n}.rb.cruby"))[0]
  om = rm[n][1] == "NOBUILD" ? nil : File.read("out-m/#{n}.out"); op = rp[n][1] == "NOBUILD" ? nil : File.read("out-p/#{n}.out")
  if (t = n.match(/\Atyped_([a-z]+)_(find_index|include|member|rindex|index|count)_([a-z0-9]+)\z/))
    typed[[t[1], t[3], op.nil? ? "nobuild" : op == co ? "right" : "wrong", om == op ? "as master" : "MOVED"]] += 1; next
  end
  m = n.match(/\A(.+?)_(find_index|include|member|rindex|index|count)_([a-z0-9]+)_([a-z]+)\z/)
  if om != co && op == co then cured[[m[1], m[3]]] += 1
  elsif op != co then stay[[m[1], m[3], m[2] == "count" ? "count" : "search", op.nil? ? "nobuild" : "wrong"]] += 1 end
end
puts "cured (receiver, needle): " + cured.sort.map { |k, v| "#{k.join("/")} #{v}" }.join(", ")
puts "not right on the piece: " + stay.sort.map { |k, v| "#{k.join("/")} #{v}" }.join(", ")
puts "typed needles: " + typed.sort.map { |k, v| "#{k.join("/")} #{v}" }.join(", ")
