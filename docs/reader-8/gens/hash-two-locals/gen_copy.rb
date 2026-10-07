#!/usr/bin/env ruby
# Family COPY: a copy of the two-named Hash must NOT share with it.
# usage: gen_copy.rb OUTDIR
require "fileutils"
out = ARGV[0]; FileUtils.mkdir_p(out)
KINDS = {
  "si"  => ['{a: 1, b: 2}', ":a", "1", ":n", "5"],
  "sti" => ['{"a" => 1, "b" => 2}', '"a"', "1", '"n"', "5"],
  "ss"  => ['{"a" => "x", "b" => "y"}', '"a"', '"x"', '"n"', '"w"'],
  "ii"  => ['{1 => 1, 2 => 2}', "1", "1", "9", "5"],
  "hn0" => ['Hash.new(0)', ":a", "1", ":n", "5"],
}
WKV = { "si" => [["1", ":v"], [":z", '"s"'], ['"k"', "2"]], "sti" => [["1", "2"], ['"z"', '"s"'], [":z", "2"]], "ss" => [["1", '"q"'], ['"z"', "3"]], "ii" => [['"k"', "2"], ["3", '"s"']], "hn0" => [["1", "5"], [":z", '"s"']] }
COPY = {
  "dup" => "X.dup", "clone" => "X.clone", "merge0" => "X.merge({})", "merge2" => "X.merge(m2)",
  "Hash" => "Hash[X]", "to_h" => "X.to_h", "select" => "X.select { |_k, _v| true }",
  "reject" => "X.reject { |_k, _v| false }", "tv" => "X.transform_values { |v| v }",
  "to_a_to_h" => "X.to_a.to_h", "emerge" => "{}.merge(X)", "compact" => "X.compact",
  "sort_to_h" => "X.to_a.reverse.to_h", "ewo" => "X.each_with_object({}) { |(k, v), a| a[k] = v }",
  "map_to_h" => "X.map { |k, v| [k, v] }.to_h", "to_h_blk" => "X.to_h { |k, v| [k, v] }",
  "tk" => "X.transform_keys { |k| k }", "except" => "X.except(K0)", "slice" => "X.slice(K0)",
  "filter" => "X.filter { |_k, _v| true }", "dupdup" => "X.dup.dup", "mergeblk" => "X.merge(X) { |_k, a, _b| a }",
}
n = 0
KINDS.each do |kk, (lit, k0, v0, kn, vn)|
  WKV[kk].each_with_index do |(wk, wv), wi|
    COPY.each do |ck, cx|
      %w[hh gg].each do |src|
        %w[on off].each do |guard|
          %w[before after].each do |cpos|     # the copy is taken before or after the store of another kind
            %w[c h g].each do |via|            # what changes afterwards
              next unless (n += 1) && (wi == 0 || (ck.sum + via.ord + cpos.size + guard.size + src.sum) % 3 == 0)
              body = ["hh = #{lit}"]
              body << "hh[#{k0}] = #{v0}" << "hh[:b] = 2" if kk == "hn0"
              body << "gg = hh"
              body << "m2 = #{lit.start_with?('Hash') ? '{c: 3}' : lit.sub(/\A\{/, '{').gsub(/\b(a|b)\b/) { $1 == 'a' ? 'c' : 'd' }.gsub('1 =>', '3 =>').gsub('2 =>', '4 =>')}" if ck == "merge2"
              cp = "cc = #{cx.gsub('X', src).gsub('K0', k0)}"
              st = (wi.odd? ? "[[#{wk}, #{wv}]].each { |k, v| gg[k] = v }" : "gg.merge!(wm)") + (guard == "off" ? " if ARGV.size > 5" : "")
              body << "wm = {#{wk} => #{wv}}" unless wi.odd?
              body.concat(cpos == "before" ? [cp, st] : [st, cp])
              case via
              when "c" then body << "cc[#{kn}] = #{vn}"
              when "h" then body << "hh[#{kn}] = #{vn}"
              when "g" then body << "gg.delete(#{k0})"
              end
              %w[hh gg cc].each { |r| body << "p #{r}.to_a" << "p #{r}.size" << "p #{r}[#{kn}]" }
              body << "p cc.equal?(hh)" << "p cc.equal?(gg)" << "p hh.equal?(gg)"
              File.write(File.join(out, format("y%05d_%s.rb", n, "#{kk}_#{wi}_#{ck}_#{src}_#{guard}_#{cpos}_#{via}")), body.join("\n") + "\n")
            end
          end
        end
      end
    end
  end
end
puts "#{Dir[File.join(out, '*.rb')].size} programs in #{out}"
