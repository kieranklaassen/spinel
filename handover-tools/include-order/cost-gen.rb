#!/usr/bin/env ruby
# cost-gen.rb OUT: programs for the compile time of the include pass.
# chain-N: N modules, each including the one before and defining one method; a class
#   includes the last and then the first (held already).
# chainx-N: the same without the second include (no module is named twice).
# wide-K: K modules each including one shared base of 20 methods; a class includes them all.
# subs-K: K subclasses each including again a module of 20 methods their superclass includes.
# subsx-K: the same subclasses with no include.
require 'fileutils'
out = ARGV[0]; FileUtils.mkdir_p(out)
[200, 1000, 2000].each do |n|
  mods = (0...n).map { |k| "module M#{k}\n#{"  include M#{k - 1}\n" if k > 0}  def m#{k} = #{k}\nend" }
  File.write("#{out}/chain-#{n}.rb", mods.join("\n") + "\nclass R\n  include M#{n - 1}\n  include M0\nend\np R.new.m0\np R.new.m#{n - 1}\n")
  File.write("#{out}/chainx-#{n}.rb", mods.join("\n") + "\nclass R\n  include M#{n - 1}\nend\np R.new.m0\np R.new.m#{n - 1}\n")
end
base = "module Base\n#{(0...20).map { |i| "  def b#{i} = #{i}" }.join("\n")}\nend"
[100, 500].each do |k|
  mods = (0...k).map { |i| "module W#{i}\n  include Base\n  def w#{i} = #{i}\nend" }
  File.write("#{out}/wide-#{k}.rb", base + "\n" + mods.join("\n") + "\nclass R\n#{(0...k).map { |i| "  include W#{i}" }.join("\n")}\nend\np R.new.b3\np R.new.w#{k - 1}\n")
end
[200, 1000].each do |k|
  subs = ->(inc) { (0...k).map { |i| "class S#{i} < Top\n#{"  include Base\n" if inc}  def s#{i} = #{i}\nend" } }
  top = "class Top\n  include Base\n  def b3 = 33\nend"
  tail = "\np S0.new.b3\np S#{k - 1}.new.b4\np S#{k - 1}.new.s#{k - 1}\n"
  File.write("#{out}/subs-#{k}.rb", base + "\n" + top + "\n" + subs.(true).join("\n") + tail)
  File.write("#{out}/subsx-#{k}.rb", base + "\n" + top + "\n" + subs.(false).join("\n") + tail)
end
puts Dir["#{out}/*.rb"].size
