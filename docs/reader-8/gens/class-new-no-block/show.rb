# show.rb OUT.jsonl NAME [FAMDIR] : CRuby / each tree's rows for one program
require "json"
file, name, fam = ARGV
File.foreach(file) do |l|
  r = JSON.parse(l)
  next unless r["f"] == name
  puts File.read("#{fam}/prog/#{name}.rb") if fam
  puts "ruby: #{r['ruby'].inspect[0, 300]}"
  (r["c"].to_a + [["twin", r["twin_c"]]]).each do |t, c|
    next if c.nil?
    if c.start_with?("REFUSED") then puts "#{t}: #{c[0, 200]}"; next end
    (r["r"][c] || {}).each do |cc, v|
      puts "#{t} #{cc}: " + (v.is_a?(String) ? v : v.map { |x| [x["k"], x["o"].to_s[0, 120], x["err"], x["sig"]].compact.inspect }.uniq.join(" | "))
    end
    puts "#{t}: C #{c} (not run: same C as another tree)" unless r["r"][c]
  end
end
