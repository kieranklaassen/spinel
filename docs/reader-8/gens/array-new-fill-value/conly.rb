#!/usr/bin/env ruby
# conly.rb DIR OUT.tsv : the generated C's sha per tree (m p), no build
require "digest"; require "open3"
dir, out = ARGV[0], ARGV[1]
files = Dir[File.join(dir, "*.rb")].sort
q = Queue.new; files.each { |f| q << f }
res = {}; mu = Mutex.new
2.times.map do
  Thread.new do
    while (f = (q.pop(true) rescue nil))
      row = %w[m p].map do |t|
        cf = "/tmp/claude-0/rrconly.#{$$}.#{Thread.current.object_id}.c"
        o, e, st = Open3.capture3("/home/claude/r8/an/#{t}/bin/spinel", f, "-c", "-o", cf, "--force")
        if st.success? && File.exist?(cf) then h = Digest::SHA1.hexdigest(File.read(cf).gsub(%r{/home/claude/r8/(an/|t5/)?[a-z0-9-]+/}, "/T/"))[0, 12]; File.delete(cf); h
        else "REFUSED:" + (e.lines.reject { |l| l =~ /warning/ }.first || e.lines.first).to_s.strip[0, 110] end
      end
      mu.synchronize { res[File.basename(f, ".rb")] = row }
    end
  end
end.each(&:join)
File.open(out, "w") { |o| res.sort.each { |k, r| o.puts(([k] + r).join("\t")) } }
puts "programs #{res.size}, refused on m #{res.count { |k, r| r[0].start_with?("REF") }}, refused on p #{res.count { |k, r| r[1].start_with?("REF") }}, C changed #{res.count { |k, r| r[0] != r[1] }}"
