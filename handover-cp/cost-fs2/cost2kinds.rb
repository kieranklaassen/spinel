# cost2kinds.rb BASE LABEL : by needle kind and compiler, instructions a lookup more than BASE, as
# include?/index/rindex with the answer used as a condition (c) and kept in a local (k); master's own count in brackets
base, lab = ARGV
D = File.dirname(__FILE__) + "/cost2out"
rd = ->(l, cc) { File.readlines("#{D}/#{l}.#{cc}.txt", chomp: true).to_h { |x| a = x.split(" ", 3); [a[0], a] } }
kinds = %w[int nint miss nil str sym true bignum frac nan bigf rat52 ary hash obj whole rat51]
%w[gcc clang].each do |cc|
  m = rd.(base, cc); x = rd.(lab, cc)
  puts "== #{cc}: kind, then cinc cidx cridx kinc kidx kridx (master's count), '!' where the output changes"
  kinds.each do |k|
    cells = %w[cinc cidx cridx kinc kidx kridx].map { |p| n = "#{p}_#{k}"; next "      -" unless m[n] && x[n]; format("%+4.0f%s(%3.0f)", (x[n][1].to_i - m[n][1].to_i) / 300000.0, x[n][2] == m[n][2] ? " " : "!", m[n][1].to_i / 300000.0) }
    puts format("%-7s %s", k, cells.join(" "))
  end
end
