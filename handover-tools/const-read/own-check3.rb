# own-check3.rb DIR [GLOB]: for each DIR/GLOB (default *-q00.rb), the lists the compiler builds
# (SPINEL_QC_DUMP, a compiler built with order-dump.patch, its path in DUMP_SPINEL) against
# CRuby's ancestors for every class
# and module the dump names. The probe is an at_exit block in front of the program.
require 'open3'
ok = bad = none = 0; shapes = Hash.new(0)
Dir["#{ARGV[0]}/#{ARGV[1] || "*-q00.rb"}"].sort.each do |f|
  _, err, _ = Open3.capture3({ "SPINEL_QC_DUMP" => "1" }, ENV.fetch("DUMP_SPINEL"), "-S", f)
  own = err.lines.grep(/^OWN /).to_h { |l| k, v = l.chomp.sub("OWN ", "").split(":", 2); k = l.chomp.sub("OWN ", "")[/\A[^ ]*(?=:( |\z))/]; [k, l.chomp.sub("OWN #{k}:", "").split] }
  (none += 1; next) if own.empty?
  names = own.keys
  probe = "at_exit { " + names.map { |k| "begin; k = Object.const_get(\"#{k}\"); if k.is_a?(Module); a = k.ancestors; i = k.is_a?(Class) ? a.index(k.superclass) : a.size; $stderr.puts \"REAL #{k}: \" + (a[1...i] - [Comparable, Kernel, Enumerable]).join(' '); end; rescue NameError; end" }.join("; ") + " }\n"
  _, e2, _ = Open3.capture3("ruby", "-e", probe + File.read(f), chdir: File.dirname(f))
  real = e2.lines.grep(/^REAL /).to_h { |l| k = l.chomp.sub("REAL ", "")[/\A[^ ]*(?=:( |\z))/]; [k, l.chomp.sub("REAL #{k}:", "").split] }
  diff = names.select { |k| real.key?(k) && real[k] != own[k] }
  shapes[File.basename(f)[/^[a-z0-9]+/]] += 1
  if diff.empty? && !real.empty? then ok += 1 else bad += 1; puts "#{f}: #{diff.first(2).map { |k| "#{k} model #{own[k].join(",")} real #{real[k].join(",")}" }.join("; ")} #{"(no probe output)" if real.empty?}" if bad <= 8 end
end
puts "ok #{ok} bad #{bad} no-model #{none}"; puts shapes.sort.map { |k, v| "#{k} #{v}" }.join(" ")
