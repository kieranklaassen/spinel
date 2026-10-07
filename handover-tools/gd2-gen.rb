#!/usr/bin/env ruby
# gd2-gen.rb OUT: one-query programs for is_a?, kind_of? and instance_of? of a rescued
# exception against a name that may or may not be the nested class of that leaf: the class
# layouts (one nested Error, two modules each with one, a nested one beside a top-level one,
# one nested in a class, two under an outer module) crossed with a constant the program
# writes under the same leaf or head (at the program's level, in another module, in a class
# inside the holder, by ||=, an alias of the holder's name), the place the query stands (a
# top-level method, a method of the holder, of a class inside it, of another module, of a
# `class Net::Late`, a block, a lambda) and the argument (bare, by path, rooted, through the
# other module). Each program raises every class in turn and prints one row.
require 'fileutils'
out = ARGV[0] or abort "usage: gd2-gen.rb OUT"
FileUtils.mkdir_p(out)
E = "class Error < StandardError; end"
LAYOUTS = {
  "one"   => ["module Net\n  #{E}\nend\n", %w[Net::Error]],
  "two"   => ["module Net\n  #{E}\nend\nmodule Disk\n  #{E}\nend\n", %w[Net::Error Disk::Error]],
  "top"   => ["module Net\n  #{E}\nend\n#{E}\n", %w[Net::Error Error]],
  "cls"   => ["class Net\n  #{E}\nend\n", %w[Net::Error]],
  "outer" => ["module Outer\n  module Net\n    #{E}\n  end\n  module Disk\n    #{E}\n  end\nend\nNet = Outer::Net\n", %w[Outer::Net::Error Outer::Disk::Error]],
}
ALIASES = {
  "none"    => "",
  "toperr"  => "Error = Plain\n",
  "topself" => "Error = Net::Error\n",
  "other"   => "module Other\n  Error = Plain\nend\n",
  "inner"   => "KW Net\n  class Client\n    Error = Plain\n  end\nend\n",
  "orw"     => "Error ||= Plain\n",
  "name2"   => "Err2 = Net::Error\n",
  "head"    => "module App\n  Net = ::Other2\nend\n",
}
SITES = {
  "topdef"  => ["def q(e) = (QUERY rescue :ne)\n", "q(e)"],
  "holder"  => ["KW Net\n  def self.q(e) = (QUERY rescue :ne)\nend\n", "Net.q(e)"],
  "client"  => ["KW Net\n  class Client\n    def q(e) = (QUERY rescue :ne)\n  end\nend\n", "Net::Client.new.q(e)"],
  "other"   => ["module Other\n  def self.q(e) = (QUERY rescue :ne)\nend\n", "Other.q(e)"],
  "compact" => ["class Net::Late\n  def q(e) = (QUERY rescue :ne)\nend\n", "Net::Late.new.q(e)"],
  "block"   => ["KW Net\n  def self.q(e) = [1].map { (QUERY rescue :ne) }\nend\n", "Net.q(e)"],
  "lambda"  => ["KW Net\n  Q = ->(e) { (QUERY rescue :ne) }\nend\n", "Net::Q.call(e)"],
  "app"     => ["module App\n  def self.q(e) = (QUERY rescue :ne)\nend\n", "App.q(e)"],
}
ARGS = %w[Error Net::Error ::Error Other::Error Err2]
n = 0
LAYOUTS.each do |ln, (defs, raised)|
  kw = ln == "cls" ? "class" : "module"
  ALIASES.each do |an, al|
    next if an == "topself" && ln == "top"
    next if %w[toperr orw topself].include?(an) && ln == "top"
    next if an == "head" && ln == "outer"
    SITES.each do |sn, (site, call)|
      next if ln == "outer" && %w[holder client compact block lambda].include?(sn)
      ARGS.each do |arg|
        next if arg == "Err2" && an != "name2"
        next if arg == "Other::Error" && !(an == "other" || sn == "other")
        %w[is_a? kind_of? instance_of?].each do |m|
          src = +"class Plain < StandardError; end\nmodule Other2\n  class Error < StandardError; end\nend\n"
          src = +"class Plain < StandardError; end\n" unless an == "head"
          src << defs << al.gsub("KW", kw) << site.gsub("KW", kw).sub("QUERY", "e.#{m}(#{arg})")
          ks = raised + %w[Plain ArgumentError] + (an == "head" ? %w[Other2::Error] : [])
          src << "row = []\n[#{ks.join(", ")}].each do |k|\n  begin\n    raise k, \"x\"\n  rescue => e\n    row << #{call}\n  end\nend\np row\n"
          File.write("#{out}/#{ln}-#{an}-#{sn}-#{arg.gsub("::", "_")}-#{m.sub("?", "")}.rb", src)
          n += 1
        end
      end
    end
  end
end
puts n
