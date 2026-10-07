#!/usr/bin/env ruby
# Bystander scan for piece 3: every corpus test with a trigger appended (a class
# with its own send and one boxed literal send that the piece splits), compiled
# to C by BASE and PIECE; reports how many C lines differ per program.
# usage: scan3.rb TESTDIR OUTDIR BASE PIECE > scan.tsv
Encoding.default_external = Encoding::UTF_8
require "fileutils"; require "open3"
td, out, base, piece = ARGV
ROOT = "/home/claude/r8/p175s"
FileUtils.mkdir_p(out)
TRIG = <<~R

  class ZzConn
    def initialize(tag) = @tag = tag
    def send(msg, flags) = "\#{@tag}:\#{msg}:\#{flags}"
    def zzhello(k) = "ZzConn#zzhello \#{k}"
  end
  class ZzPeer
    def zzhello(k) = "ZzPeer#zzhello \#{k}"
  end
  [ZzConn.new(:a), ZzPeer.new].each { |zc| puts zc.send(:zzhello, 0) }
R
Dir[File.join(td, "*.rb")].sort.each do |f|
  s = File.binread(f)
  next if s =~ /require_relative|__END__/
  b = File.basename(f, ".rb")
  t = File.join(out, "#{b}.rb")
  File.binwrite(t, s + TRIG)
  cs = [base, piece].map do |tr|
    cf = File.join(out, "#{b}.#{tr}.c")
    o, e, st = Open3.capture3("#{ROOT}/#{tr}/bin/spinel", t, "-c", "--no-line-map", "-o", cf, "--force")
    st.success? && File.exist?(cf) ? cf : nil
  end
  if cs[0].nil? && cs[1].nil? then puts "#{b}\tREFUSED_BOTH"
  elsif cs[0].nil? then puts "#{b}\tNOW_BUILDS"
  elsif cs[1].nil? then puts "#{b}\tNOW_REFUSED"
  else
    d = `diff #{cs[0]} #{cs[1]} | grep -c '^[<>]'`.to_i
    puts "#{b}\t#{d}"
  end
  cs.compact.each { |c| File.delete(c) }
  File.delete(t)
  $stdout.flush
end
