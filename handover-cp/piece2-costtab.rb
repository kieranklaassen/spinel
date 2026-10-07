# costtab.rb FILE... : instructions an op-assign, the pick minus master (2,000,000 op-assigns)
h = Hash.new { |hh, k| hh[k] = {} }
ARGV.each { |f| File.readlines(f, chomp: true).each { |l| t, cc, n, ir = l.split; h[[n, cc]][t] = ir } }
names = h.keys.map(&:first).uniq
names.each do |n|
  cells = %w[cc clang].map do |cc|
    r = h[[n, cc]]; m, p = r.values_at(r.keys.find { |k| k.start_with?("m") }, r.keys.find { |k| k.start_with?("p") })
    (m =~ /\A\d+\z/ && p =~ /\A\d+\z/) ? format("%+.2f (%s -> %s)", (p.to_i - m.to_i) / 2_000_000.0, m, p) : "#{m} #{p}"
  end
  puts "#{n.ljust(12)} gcc #{cells[0]}   clang #{cells[1]}"
end
