#!/usr/bin/env ruby
# gd4-gen.rb OUT: one-row programs asking an exception is_a?/instance_of? where a constant made
# by Class.new (or an alias constant) has the name of a class two modules also name. Net and
# Disk always name a class Error. MAKERS write the constant, PLACES say in which body, SITES
# where the question is asked, ARGS how the class is named. A row: one cell per raised class.
out = ARGV[0] or abort "usage: gd4-gen.rb OUT"
require 'fileutils'; FileUtils.mkdir_p(out)
MAKERS = {
  "cn"  => ["Error", "Error = Class.new(StandardError)"],
  "cnn" => ["Error", "Error = Class.new(Net::Error)"],
  "cnb" => ["Error", "Error = Class.new(StandardError) do\ndef note = 1\nend"],
  "al"  => ["Error", "Error = Plain"],
  "cf"  => ["Fault", "Fault = Class.new(StandardError)"],
}
PLACES = {
  "top"   => [->(mk) { mk + "\n" }, "", nil],
  "inner" => [->(mk) { "module Net\nmodule Inner\n#{mk}\nend\nend\n" }, "Net::Inner::",
              ->(q) { ["module Net\nmodule Inner\ndef self.q(e) = #{q}\nend\nend\n", "Net::Inner.q(e)"] }],
  "cls"   => [->(mk) { "class Conn\n#{mk}\nend\n" }, "Conn::",
              ->(q) { ["class Conn\ndef q(e) = #{q}\nend\n", "Conn.new.q(e)"] }],
  "other" => [->(mk) { "module Other\n#{mk}\nend\n" }, "Other::",
              ->(q) { ["module Other\ndef self.q(e) = #{q}\nend\n", "Other.q(e)"] }],
  "base"  => [->(mk) { "class Base\n#{mk}\nend\nclass Sub < Base\nend\n" }, "Base::",
              ->(q) { ["class Sub\ndef q(e) = #{q}\nend\n", "Sub.new.q(e)"] }],
}
SITES = {
  "top"    => ->(q) { ["", q] },
  "place"  => nil,
  "net"    => ->(q) { ["module Net\ndef self.q(e) = #{q}\nend\n", "Net.q(e)"] },
  "neterr" => ->(q) { ["module Net\nclass Error\ndef self.q(e) = #{q}\nend\nend\n", "Net::Error.q(e)"] },
  "disk"   => ->(q) { ["module Disk\ndef self.q(e) = #{q}\nend\n", "Disk.q(e)"] },
}
n = 0
MAKERS.each do |mn, (leaf, mk)|
  PLACES.each do |pn, (place, pre, psite)|
    SITES.each do |sn, site|
      site = psite if sn == "place"
      next unless site
      { "bare" => leaf, "path" => pre + leaf, "root" => "::" + leaf, "net" => "Net::Error" }.each do |an, arg|
        next if an == "path" && pre.empty?
        %w[is_a? instance_of?].each do |m|
          body, call = site.("(e.#{m}(#{arg}) rescue :ne)")
          src = +"module Net\n  class Error < StandardError; end\nend\nmodule Disk\n  class Error < StandardError; end\nend\nclass Plain < StandardError; end\n"
          src << place.(mk) << body
          src << "row = []\n[Net::Error, Disk::Error, Plain, #{pre + leaf}].each do |k|\n  begin\n    raise k, \"x\"\n  rescue => e\n    row << #{call}\n  end\nend\np row\n"
          File.write("#{out}/#{mn}-#{pn}-#{sn}-#{an}-#{m.delete("?")}.rb", src); n += 1
        end
      end
    end
  end
end
puts n
