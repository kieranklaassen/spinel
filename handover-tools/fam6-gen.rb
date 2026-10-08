# fam6-gen.rb FAM OUT: the witnesses of the guard on a method's read. 96 of gen.rb's programs
# (FAM/p, FAM/t) with `puts "start"` on the line before the constant's write.
fam, out = ARGV
%w[p t].each do |d|
  Dir.mkdir("#{out}/#{d}") rescue nil
  %w[arr int mod myerr parent str struct user].product(%w[direct_yes each_mixed ivar_poly param_poly safe_nav select], %w[isa iof]).each do |c, k, q|
    n = "#{c}_#{k}_#{q}"; src = File.read("#{fam}/#{d}/b1_#{n}.rb").lines
    i = File.read("#{fam}/p/b1_#{n}.rb").lines.index { |l| l.start_with?("K = ") } or abort n
    File.write("#{out}/#{d}/b6_#{n}.rb", (src[0, i] + ["puts \"start\"\n"] + src[i..]).join)
    File.write("#{out}/#{d}/b6_#{n}.exp", File.read("#{fam}/p/b1_#{n}.exp").sub("\n", "\nstart\n")) if d == "p"
  end
end
