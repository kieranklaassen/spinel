#!/usr/bin/env ruby
# half2.rb : for each program master does not build and the then piece answers
# wrong in a line (reach.ft.cc.list): the C of master and of the piece for the
# SAME program, temporaries renumbered and the frame's declaration set aside,
# through diff. Every line of master's C that the piece takes out or changes
# must be a blockless call's (it holds sp_enum_of_one): the lines that compute
# the block and block-pass forms are then master's text on both trees. What the
# piece adds is the blockless call's own code. Nothing is removed.
require "open3"; require "fileutils"
S = File.expand_path("..", __dir__); F = "#{S}/fx"; W = "/home/claude/wt"; out = "#{S}/fr/half2"; FileUtils.mkdir_p(out)
names = File.readlines("#{S}/fr/reach3.a.list", chomp: true).reject(&:empty?)
norm = ->(s) { s.lines.map { |l| l.gsub(/_t\d+/, "_tN").gsub(/_snr?\d+/, "_snN").sub(/struct \{ sp_gc_frame_hdr h;.*SP_GC_ROOT_FRAME\(_gcf\);/, "FRAME") }.join }
ok = 0; bad = []; taken = 0; added = 0
names.each do |n|
  fs = %w[m9 fr].map do |t|
    f = "#{out}/#{n}.#{t}.c"
    _o, s = Open3.capture2e("#{W}/#{t}/bin/spinel", "-c", "--no-line-map", "#{F}/fam/progs/#{n}.rb", "-o", f)
    raise "no C #{n} #{t}" unless s.success?
    File.write(f + ".norm", norm.(File.read(f))); f + ".norm"
  end
  d, = Open3.capture2("diff", *fs)
  lt = d.lines.grep(/\A< /); gt = d.lines.grep(/\A> /)
  taken += lt.size; added += gt.size
  off = lt.reject { |l| l.include?("sp_enum_of_one(") }
  off.empty? ? ok += 1 : bad << [n, "#{off.size} of master's lines changed with no blockless call: #{off[0].strip[0, 140]}"]
end
puts "programs #{names.size}: in #{ok} every line of master's C the piece changes is a blockless call's (#{taken} lines of master's, #{added} of the piece's); other #{bad.size}"
bad.first(10).each { |x| puts "  " + x.join("  ") }
