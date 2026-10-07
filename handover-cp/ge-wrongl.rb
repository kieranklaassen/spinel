# wrongl.rb FIXOUT MASTEROUT ROWS: for each program wrong under the fix, the wrong lines (index: cruby | fix | master)
fo, mo, rows = ARGV
agg = Hash.new(0)
File.readlines(rows).each do |l|
  f = l.chomp.split("\t")
  next unless f[1] == "WRONG"
  n = f[0]
  c = File.readlines("#{fo}/#{n}.cruby.out", chomp: true)
  x = File.readlines("#{fo}/#{n}.out", chomp: true)
  m = File.exist?("#{mo}/#{n}.out") ? File.readlines("#{mo}/#{n}.out", chomp: true) : nil
  src = File.readlines("fam4/progs/#{n}.rb", chomp: true)
  plines = src.select { |s| s =~ /^p[ (]/ }
  w = []
  [c.size, x.size].max.times do |i|
    next if c[i] == x[i]
    w << "#{plines[i]} => cruby #{c[i].inspect} fix #{x[i].inspect}"
    agg[[n.split("__")[0], plines[i], c[i], x[i]]] += 1
  end
  puts "#{n}: #{w.size} wrong: #{w.join(' ; ')}" if ENV["V"]
end
agg.sort.each { |k, v| puts "#{v}\t#{k.inspect}" }
