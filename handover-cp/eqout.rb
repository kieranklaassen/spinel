# eqout.rb ROWS_A:OUT_A ROWS_B:OUT_B : do two runs of one family print the same bytes, program by program, at SPINEL_GC_STRESS unset, 1, 2?
Encoding.default_external = Encoding::BINARY
a, b = ARGV.map { |t| f, d = t.split(":"); [File.readlines(f, chomp: true).to_h { |l| x = l.split("\t", -1); [x[0], x] }, d] }
same = 0; diff = []; only = []
(a[0].keys | b[0].keys).sort.each do |n|
  ra, rb = a[0][n], b[0][n]
  (only << n; next) if ra.nil? || rb.nil?
  if ra[1] == "NOBUILD" || rb[1] == "NOBUILD"
    ra[1] == rb[1] ? same += 1 : diff << "#{n} (#{ra[1]} / #{rb[1]})"
    next
  end
  eq = ["", "1", "2"].all? { |s| File.binread("#{a[1]}/#{n}.out#{s}") == File.binread("#{b[1]}/#{n}.out#{s}") }
  eq ? same += 1 : diff << "#{n} (#{ra[1..3].join(",")} / #{rb[1..3].join(",")})"
end
puts "same bytes at the three levels: #{same}; differ: #{diff.size}; in one run only: #{only.size}"
puts "  " + diff.first(12).join("\n  ") unless diff.empty?
puts "  only: " + only.first(8).join(" ") unless only.empty?
