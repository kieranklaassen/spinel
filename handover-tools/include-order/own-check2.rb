# own-check2.rb DIR SPINEL: for each DIR/*-q00.rb, the order of modules SPINEL works out
# for every class and module (printed under SPINEL_INC_DUMP by a compiler built with
# order-dump.patch on the piece) against CRuby's ancestors. The program runs whole; the
# probe is an at_exit block in front of it, writing to stderr.
require 'open3'; require 'tempfile'
ok = bad = none = 0; shapes = Hash.new(0)
Dir["#{ARGV[0]}/*-q00.rb"].sort.each do |f|
  _, err, _ = Open3.capture3({ "SPINEL_INC_DUMP" => "1" }, ARGV[1], "-S", f)
  own = err.lines.grep(/^OWN /).to_h { |l| k, v = l.chomp.sub("OWN ", "").split(":", 2); [k, v.split] }
  (none += 1; next) if own.empty?
  names = own.keys.select { |k| k =~ /\A[A-Z][A-Za-z0-9]*\z/ }
  probe = "at_exit { " + names.map { |k| "begin; k = Object.const_get(:#{k}); if k.is_a?(Module); a = k.ancestors; i = k.is_a?(Class) ? a.index(k.superclass) : a.size; $stderr.puts \"REAL #{k}: \" + (a[1...i] - [Comparable, Kernel, Enumerable]).join(' '); end; rescue NameError; end" }.join("; ") + " }\n"
  _, e2, _ = Open3.capture3("ruby", "-e", probe + File.read(f), chdir: File.dirname(f))
  real = e2.lines.grep(/^REAL /).to_h { |l| k, v = l.chomp.sub("REAL ", "").split(":", 2); [k, v.to_s.split.map { |x| x.sub("NS::", "") }] }
  diff = names.select { |k| real.key?(k) && real[k] != own[k] }
  shapes[File.basename(f)[/^[a-z0-9]+/]] += 1
  if diff.empty? && !real.empty? then ok += 1 else bad += 1; puts "#{f}: #{diff.first(2).map { |k| "#{k} model #{own[k].join(",")} real #{real[k].join(",")}" }.join("; ")} #{"(no probe output)" if real.empty?}" if bad <= 8 end
end
puts "ok #{ok} bad #{bad} no-model #{none}"; puts shapes.sort.map { |k, v| "#{k} #{v}" }.join(" ")
