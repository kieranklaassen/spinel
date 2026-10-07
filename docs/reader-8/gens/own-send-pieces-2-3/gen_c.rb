#!/usr/bin/env ruby
# Family gc: corpus tests that call send / __send__ / public_send and define none,
# with a class's own send set beside them.  usage: gen_c.rb TESTDIR OUTDIR
require "fileutils"
td, out = ARGV
FileUtils.mkdir_p(out)
TA = <<~R

  class ZzMailer
    def send(msg, flags) = "zz:\#{msg}:\#{flags}"
  end
  puts ZzMailer.new.send("x", 1)
R
TB = <<~R

  class ZzConn
    def initialize(tag) = @tag = tag
    def send(msg) = "\#{@tag}:\#{msg}"
    def zzhello = "ZzConn#zzhello"
  end
  class ZzPeer
    def zzhello = "ZzPeer#zzhello"
  end
  [ZzConn.new(:a), ZzPeer.new].each { |zc| puts zc.send(:zzhello) }
R
TC_TOP = <<~R
  class ZzMailer
    def send(msg, flags) = "zz:\#{msg}:\#{flags}"
    def __send__(msg, flags) = "zzd:\#{msg}:\#{flags}"
    def public_send(msg, flags) = "zzp:\#{msg}:\#{flags}"
  end
R
TC_END = "\nputs ZzMailer.new.send(\"x\", 1)\n"
n = 0
Dir[File.join(td, "*.rb")].sort.each do |f|
  s = File.read(f, encoding: "UTF-8")
  next unless s.valid_encoding?
  next unless s =~ /(send|__send__|public_send)[ (]/
  next if s =~ /def (self\.)?(send|__send__|public_send)\b/
  next if s =~ /require_relative|__FILE__|__dir__|STDIN|\$stdin|gets\b|ARGF|DATA\b/
  b = File.basename(f, ".rb").gsub(/[^A-Za-z0-9_]/, "_")
  File.write(File.join(out, "ca_#{b}.rb"), s + TA)
  File.write(File.join(out, "cb_#{b}.rb"), s + TB)
  head = s.lines.take_while { |l| l.start_with?("#") }.join
  rest = s.lines.drop_while { |l| l.start_with?("#") }.join
  File.write(File.join(out, "cc_#{b}.rb"), head + TC_TOP + rest + TC_END)
  n += 3
end
puts "#{n} programs"
