#!/usr/bin/env ruby
# fam8-gen.rb OUT: programs that write or hide a constant by its name, or define is_a?,
# kind_of? or instance_of? themselves. The change leaves every one of them alone.
out = ARGV[0] or abort "usage: fam8-gen.rb OUT"
Dir.mkdir("#{out}/p") rescue nil
T = { int: ["", "Integer", "String", "7", '"s"'], str: ["", "String", "Integer", '"s"', "7"],
      user: ["class Pt; end\nclass Qt; end\n", "Pt", "Qt", "Pt.new", "Qt.new"] }
n = 0
T.each do |t, (su, c, o, y, no)|
  %w[is_a? kind_of? instance_of?].each do |q|
    show = "p #{y}.#{q}(K), #{no}.#{q}(K)\np [#{y}, #{no}].map { |v| v.#{q}(K) }\n"
    own = ->(body) { "#{su}class Odd\n#{body}\nend\nK = Odd\np Odd.new.#{q}(K)\np [Odd.new, #{y}].map { |v| v.#{q}(K) }\n" }
    {
      constset:      "#{su}K = #{c}\nObject.const_set(:K, #{o})\n#{show}",
      constset_str:  "#{su}K = #{c}\nObject.const_set(\"K\", #{o})\n#{show}",
      constset_send: "#{su}K = #{c}\nObject.send(:const_set, :K, #{o})\n#{show}",
      constset_same: "#{su}K = #{c}\nObject.const_set(:K, #{c})\n#{show}",
      privconst:     "#{su}module Cfg\n  K = #{c}\n  private_constant :K\n  def self.t(v) = v.#{q}(K)\nend\ndef out(v)\n  v.#{q}(Cfg::K)\nrescue NameError\n  false\nend\np Cfg.t(#{y}), Cfg.t(#{no})\np out(#{y}), out(#{no})\n",
      own_def:       own.("  def #{q}(k) = false"),
      own_alias:     own.("  def mine(k) = false\n  alias #{q} mine"),
      own_define:    own.("  define_method(:#{q}) { |k| false }"),
      own_other:     "#{su}class Odd\n  def #{q}(k) = true\nend\nK = #{c}\np [#{y}, #{no}, Odd.new].map { |v| v.#{q}(K) }\n",
    }.each { |s, text| File.write("#{out}/p/b8_#{s}_#{t}_#{q.delete('?')}.rb", text); n += 1 }
  end
end
puts n
