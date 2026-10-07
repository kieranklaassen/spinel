# crtwin.rb FAM OUT : CRuby on each program and on its keyword twin; lists those where the two differ
require "open3"
fam, out = ARGV
res = []
Dir["#{fam}/twin/*.rb"].sort.each do |t|
  n = File.basename(t)
  next unless File.exist?("#{fam}/prog/#{n}")
  a = Open3.capture3({ "LANG" => "C.UTF-8" }, "timeout", "20", "ruby", "--enable-frozen-string-literal", n, chdir: "#{fam}/prog")
  b = Open3.capture3({ "LANG" => "C.UTF-8" }, "timeout", "20", "ruby", "--enable-frozen-string-literal", n, chdir: "#{fam}/twin")
  ea = a[1].lines.grep(/\(([A-Z]\w*(::\w+)*)\)$/).first.to_s[/\(([A-Z][\w:]*)\)$/, 1]
  eb = b[1].lines.grep(/\(([A-Z]\w*(::\w+)*)\)$/).first.to_s[/\(([A-Z][\w:]*)\)$/, 1]
  same = a[0] == b[0] && a[2].exitstatus == b[2].exitstatus && ea == eb
  res << "#{n.sub(/\.rb\z/, '')}\t#{same ? 'same' : 'DIFFERS'}"
end
File.write(out, res.join("\n") + "\n")
puts "#{res.size} twins; CRuby differs between program and twin: #{res.count { |l| l.end_with?('DIFFERS') }}"
