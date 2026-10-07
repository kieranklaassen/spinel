#!/usr/bin/env ruby
# Family EMPTY: `h = {}; g = h` (or Hash.new), pairs stored through h, read through g.
require "fileutils"
out = ARGV[0]; FileUtils.mkdir_p(out)
INIT = { "lit" => "{}", "new" => "Hash.new" }
PAIRS = { "si" => [[":a", "1"], [":b", "2"]], "sti" => [['"a"', "1"], ['"b"', "2"]], "ss" => [['"a"', '"x"'], ['"b"', '"y"']], "mix" => [[":a", "1"], ['"b"', '"x"']], "ii" => [["1", "10"], ["2", "20"]] }
STORE = {
  "idx"    => ->(n, ps) { ps.map { |k, v| "#{n}[#{k}] = #{v}" } },
  "store"  => ->(n, ps) { ps.map { |k, v| "#{n}.store(#{k}, #{v})" } },
  "merge"  => ->(n, ps) { ["mm = {#{ps.map { |k, v| "#{k} => #{v}" }.join(', ')}}", "#{n}.merge!(mm)"] },
  "mergel" => ->(n, ps) { ["#{n}.merge!({#{ps.map { |k, v| "#{k} => #{v}" }.join(', ')}})"] },
  "update" => ->(n, ps) { ["mm = {#{ps.map { |k, v| "#{k} => #{v}" }.join(', ')}}", "#{n}.update(mm)"] },
  "replace" => ->(n, ps) { ["mm = {#{ps.map { |k, v| "#{k} => #{v}" }.join(', ')}}", "#{n}.replace(mm)"] },
  "blk"    => ->(n, ps) { ["[#{ps.map { |k, v| "[#{k}, #{v}]" }.join(', ')}].each { |k, v| #{n}[k] = v }"] },
  "pr"     => ->(n, ps) { ["[#{ps.map { |k, v| "[#{k}, #{v}]" }.join(', ')}].each { |pr| #{n}[pr[0]] = pr[1] }"] },
  "meach"  => ->(n, ps) { ["mm = {#{ps.map { |k, v| "#{k} => #{v}" }.join(', ')}}", "mm.each { |k, v| #{n}[k] = v }"] },
  "orset"  => ->(n, ps) { ps.map { |k, v| "#{n}[#{k}] ||= #{v}" } },
  "put"    => ->(n, ps) { ps.map { |k, v| "put(#{n}, #{k}, #{v})" } },
  "fill"   => ->(n, ps) { ["fill(#{n}, [#{ps.map { |k, v| "[#{k}, #{v}]" }.join(', ')}])"] },
  "while"  => ->(n, ps) { ["ks = [#{ps.map(&:first).join(', ')}]", "vs = [#{ps.map(&:last).join(', ')}]", "i = 0", "while i < ks.size", "  #{n}[ks[i]] = vs[i]", "  i += 1", "end"] },
  "zip"    => ->(n, ps) { ["[#{ps.map(&:first).join(', ')}].zip([#{ps.map(&:last).join(', ')}]).each { |k, v| #{n}[k] = v }"] },
  "eachwo" => ->(n, ps) { ["[#{ps.map { |k, v| "[#{k}, #{v}]" }.join(', ')}].each_with_object(#{n}) { |(k, v), a| a[k] = v }"] },
}
n = 0
INIT.each do |ik, il|
  PAIRS.each do |pk, ps|
    STORE.each do |sk, st|
      # the second name before the stores; after the first store; two more names
      %w[before mid chain].each do |pos|
        body = []
        body << "def put(x, k, v)" << "  x[k] = v" << "end" if sk == "put"
        body << "def fill(x, prs)" << "  prs.each { |k, v| x[k] = v }" << "end" if sk == "fill"
        body << "hh = #{il}"
        case pos
        when "before" then body << "gg = hh"; body.concat(st.call("hh", ps)); rd = %w[gg hh]
        when "mid" then body.concat(st.call("hh", ps.first(1))); body << "gg = hh"; body.concat(st.call("hh", ps.last(1)).reject { |l| l =~ /\A(def|mm = |ks = |vs = |i = 0)/ && false }); rd = %w[gg hh]
        when "chain" then body << "gg = hh" << "ff = gg"; body.concat(st.call("hh", ps)); rd = %w[ff gg hh]
        end
        rd.each { |r| body << "p #{r}.size" << "p #{r}.to_a" }
        body << "p gg.equal?(hh)"
        n += 1
        File.write(File.join(out, format("e%04d_%s.rb", n, "#{ik}_#{pk}_#{sk}_#{pos}")), body.join("\n") + "\n")
      end
    end
  end
end
puts "#{n} programs in #{out}"
