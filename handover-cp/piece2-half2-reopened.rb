#!/usr/bin/env ruby
# half2r.rb : rule (b) half 2 for the same three programs: master's C and the
# piece's C, temporaries renumbered and the frame's declaration set aside,
# through diff. Every changed line must be the cured statement's own code
# (master's `sp_poly_recv_i("|", ...)` store, the piece's slot read and
# `sp_poly_bitop_int_first(` store), and the operand's code, `(lv_t & 1)`,
# must stand in both: what computes the wrong value is master's text.
require "open3"
S = File.expand_path("..", __dir__)
norm = ->(f) {
  File.readlines(f, chomp: true).reject { |l| l =~ /SP_GC_ROOT_FRAME\(_gcf\)|^\s*SP_GC_SAVE\(\);$/ }.map { |l|
    l.gsub(/_wb\d+/, "_wbN").gsub(/_(rcls|rmsg|ce)_\d+/, '_\1_N').gsub(/\b_t\d+\b/, "_tN").gsub(/_gcf\.v\[\d+\]/, "_gcf.v[N]") }
}
ok = 0
%w[obj boxed self].each do |s|
  n = "true__band__lit__or__#{s}"
  a, b = %w[m9 p2z].map { |t| p = "#{S}/twinr/#{n}.#{t}.n.c"; File.write(p, norm.("#{S}/twinr/#{n}.#{t}.c").join("\n") + "\n"); p }
  d, _ = Open3.capture2("diff", a, b)
  ml = d.lines.grep(/^< /); xl = d.lines.grep(/^> /)
  recv = /^[<>] \s*sp_Box \* _tN = \S+;( _gcf\.v\[N\] = _tN->iv_v;)?$/
  oper = /\(lv_l?t & 1\)/
  good = ml.all? { |l| (l.include?(%q{sp_poly_recv_i("|"}) && l =~ oper) || l =~ recv } &&
         xl.all? { |l| (l.include?("sp_poly_bitop_int_first(") && l =~ oper) || l =~ recv } &&
         ml.count { |l| l =~ oper } == 1 && xl.count { |l| l =~ oper } == 1
  ok += 1 if good
  puts "#{n}: master lines #{ml.size}, piece lines #{xl.size}: #{good ? "only the cured statement" : "READ BY HAND"}"
  puts d unless good
end
puts "half 2: #{ok} of 3"
