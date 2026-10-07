#!/usr/bin/env ruby
# gd3-gen.rb OUT: one-row programs asking an exception is_a?/kind_of?/instance_of? with a name
# that an included module, a superclass or an enclosing module may also hold. Two modules (Net,
# Disk) always name a class Error; a third holder is added (DEFS), and the question is asked
# from a body that reaches the holder lexically, through an include, or through a superclass.
out = ARGV[0]
DEFS = {
  "none"     => ["", []],
  "mixin"    => ["module Mixin\n  module Net\n    class Error < StandardError; end\n  end\nend\n", ["Mixin::Net::Error"]],
  "base"     => ["class Base\n  module Net\n    class Error < StandardError; end\n  end\nend\n", ["Base::Net::Error"]],
  "wrap"     => ["module Wrap\n  module Net\n    class Error < StandardError; end\n  end\nend\n", ["Wrap::Net::Error"]],
  "mixinerr" => ["module Mixin\n  class Error < StandardError; end\nend\n", ["Mixin::Error"]],
  "baseerr"  => ["class Base\n  class Error < StandardError; end\nend\n", ["Base::Error"]],
}
SITES = {
  "top"     => ->(q) { ["", "->(e) { #{q} }"] },
  "net"     => ->(q) { ["module Net\n  def self.q(e) = #{q}\nend\n", "->(e) { Net.q(e) }"] },
  "incl"    => ->(q) { ["module Mixin; end\nmodule Host\n  include Mixin\n  def self.q(e) = #{q}\nend\n", "->(e) { Host.q(e) }"] },
  "clsincl" => ->(q) { ["module Mixin; end\nclass Host\n  include Mixin\n  def q(e) = #{q}\nend\n", "->(e) { Host.new.q(e) }"] },
  "sub"     => ->(q) { ["class Base; end\nclass Sub < Base\n  def q(e) = #{q}\nend\n", "->(e) { Sub.new.q(e) }"] },
  "wrap"    => ->(q) { ["module Wrap\n  def self.q(e) = #{q}\nend\n", "->(e) { Wrap.q(e) }"] },
  "wrapc"   => ->(q) { ["module Wrap; end\nclass Wrap::Host\n  def q(e) = #{q}\nend\n", "->(e) { Wrap::Host.new.q(e) }"] },
  "copied"  => ->(q) { ["module Mixin\n  def q(e) = #{q}\nend\nclass Host\n  include Mixin\nend\n", "->(e) { Host.new.q(e) }"] },
  "netincl" => ->(q) { ["module Mixin; end\nmodule Net\n  class Host\n    include Mixin\n    def q(e) = #{q}\n  end\nend\n", "->(e) { Net::Host.new.q(e) }"] },
}
ARGS = { "Error" => "Error", "Net_Error" => "Net::Error", "_Net_Error" => "::Net::Error", "Disk_Error" => "Disk::Error" }
n = 0
DEFS.each do |dn, (dsrc, dcls)|
  SITES.each do |sn, site|
    ARGS.each do |an, arg|
      %w[is_a? kind_of? instance_of?].each do |m|
        body, call = site.("(e.#{m}(#{arg}) rescue :ne)")
        src = +"module Net\n  class Error < StandardError; end\nend\nmodule Disk\n  class Error < StandardError; end\nend\nclass Plain < StandardError; end\n"
        src << dsrc << body << "Q = #{call}\nrow = []\n[#{(%w[Net::Error Disk::Error Plain] + dcls).join(", ")}].each do |k|\n  begin\n    raise k, \"x\"\n  rescue => e\n    row << Q.call(e)\n  end\nend\np row\n"
        File.write("#{out}/#{dn}-#{sn}-#{an}-#{m.delete("?")}.rb", src); n += 1
      end
    end
  end
end
puts n
