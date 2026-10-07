#!/usr/bin/env ruby
# tfntab.rb PROGS MOUT POUT TWOUT [PCOUT] : the reopened true/false/nil family by program
# (each prints one line: the slot, or the class of the raise it rescues).
# CRuby's line, master's, the piece's; for a line master raised and the piece
# answers wrong, the twin's line on master. Nothing is removed.
Encoding.default_external = Encoding::BINARY
progs, mout, pout, twout, pcout = ARGV
names = Dir["#{progs}/*.rb"].map { |f| File.basename(f, ".rb") }.sort
rd = ->(d, n) { f = "#{d}/#{n}.out"; File.exist?(f) ? File.read(f) : nil }
kind = ->(o, co) {
  next "nobuild" if o.nil?
  next "right" if o == co
  next "died" if o.include?("[exit:")
  o.strip =~ /\A(NoMethodError|TypeError)\z/ ? "raise" : "wrong" }
st = Hash.new(0); reached = []; viol = []; clangdiff = 0; by = Hash.new(0)
names.each do |n|
  co = Marshal.load(File.binread("#{progs}/#{n}.rb.cruby"))[0]
  mo, po = rd.(mout, n), rd.(pout, n)
  km, kp = kind.(mo, co), kind.(po, co)
  st["#{km} -> #{kp}"] += 1
  viol << [n, "(a)"] if km == "right" && kp != "right"
  if %w[raise died nobuild].include?(km) && kp == "wrong"
    tw = rd.(twout, n)
    reached << [n, co.strip, mo.to_s.strip, po.strip, tw.to_s.strip, tw == po]
    c, o, a, s = n.split("__"); by["slot #{s}, #{a}="] += 1
  end
  clangdiff += 1 if pcout && rd.(pcout, n) != po
end
puts "programs: #{names.size}"
st.sort.each { |k, v| puts format("  %-20s %d", k, v) }
puts "rule (a): #{viol.size}"; viol.each { |v| puts "  #{v.join(" ")}" }
puts "reached (master raised, the piece answers wrong): #{reached.size}; twin on master prints the piece's bytes: #{reached.count { |r| r[5] }}"
by.sort.each { |k, v| puts "  #{k}: #{v}" }
reached.each { |r| puts "  #{r[0]}: cruby=#{r[1]} master=#{r[2]} piece=#{r[3]} twin_on_master=#{r[4]} #{r[5] ? "HOLDS" : "DIFFERS"}" } if ENV["LIST"]
puts "clang output differs from gcc's (the piece): #{clangdiff}" if pcout
