# tab.rb MASTER.tsv FIX.tsv : cross table of verdicts (stress unset), and rule checks over all three stress levels
m = File.readlines(ARGV[0], chomp: true).map { |l| l.split("\t", -1) }.to_h { |r| [r[0], r] }
f = File.readlines(ARGV[1], chomp: true).map { |l| l.split("\t", -1) }.to_h { |r| [r[0], r] }
RIGHT = %w[same raise_same]
t = Hash.new(0); worse = []; unstable = []
f.each do |n, fr|
  mr = m[n] or next
  unstable << n unless fr[1..3].uniq.size == 1 && mr[1..3].uniq.size == 1
  (1..3).each do |i|
    t[[mr[i], fr[i]]] += 1 if i == 1
    # (a) right on master, not right on the piece; (b) a raise, no build or crash on master, a silent wrong answer on the piece
    worse << [n, i, mr[i], fr[i]] if (RIGHT.include?(mr[i]) && !RIGHT.include?(fr[i])) ||
                                     (%w[raise_diff NOBUILD CRASH RAISE_WHERE_RIGHT].include?(mr[i]) && fr[i] == "WRONG") ||
                                     (mr[i] == "NOBUILD" && fr[i] == "CRASH")
  end
end
puts "programs in both: #{(f.keys & m.keys).size}"
t.sort.each { |(a, b), c| puts format("%-18s -> %-18s %d", a, b, c) }
puts "differs between stress levels: #{unstable.size} #{unstable.first(5).join(' ')}"
puts "rule (a)/(b) breaks: #{worse.size}"
worse.first(20).each { |w| puts "  " + w.join(" ") }
