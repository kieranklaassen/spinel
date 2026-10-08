# cost programs for the include pass with a module's super chain
def mods(n) = (0...n).map { |i| "module Tag#{i}\n  def tag#{i} = \"t#{i}\"\nend\nmodule Loud#{i}\n  include Tag#{i}\n  def tag#{i} = super.upcase\nend" }.join("\n")
# chain-K: one chain module, K classes including it (the new path, K times)
[200, 1000].each do |k|
  File.write("chain-#{k}.rb", mods(1) + "\n" + (0...k).map { |i| "class C#{i}\n  include Loud0\n  def c#{i} = #{i}\nend" }.join("\n") + "\np C0.new.tag0\np C#{k - 1}.new.tag0\n")
end
# mods-M: M chain modules, one class each
[200, 1000].each do |m|
  File.write("mods-#{m}.rb", mods(m) + "\n" + (0...m).map { |i| "class C#{i}\n  include Loud#{i}\nend" }.join("\n") + "\np C0.new.tag0\np C#{m - 1}.new.tag#{m - 1}\n")
end
# held-K: chain-K plus a class that reaches a module twice (declined: the program-wide check is paid, the copy is master's)
[200, 1000].each do |k|
  File.write("held-#{k}.rb", mods(1) + "\n" + (0...k).map { |i| "class C#{i}\n  include Loud0\n  def c#{i} = #{i}\nend" }.join("\n") + "\nclass Twice\n  include Tag0\n  include Loud0\nend\np C0.new.c0\n")
end
# plain-K: K classes including a module of 20 methods with no super (left alone)
[1000].each do |k|
  File.write("plain-#{k}.rb", "module Base\n#{(0...20).map { |i| "  def b#{i} = #{i}" }.join("\n")}\nend\n" + (0...k).map { |i| "class C#{i}\n  include Base\n  def c#{i} = #{i}\nend" }.join("\n") + "\np C0.new.b3\np C#{k - 1}.new.b4\n")
end
# big-N: one module with a chain of N methods each calling super into Tag, 50 classes
[200].each do |n|
  tag = "module Tag\n#{(0...n).map { |i| "  def t#{i} = \"t#{i}\"" }.join("\n")}\nend"
  loud = "module Loud\n  include Tag\n#{(0...n).map { |i| "  def t#{i} = super.upcase" }.join("\n")}\nend"
  File.write("big-#{n}.rb", tag + "\n" + loud + "\n" + (0...50).map { |i| "class C#{i}\n  include Loud\nend" }.join("\n") + "\np C0.new.t0\np C49.new.t#{n - 1}\n")
end
# big-50: one module of 50 methods each calling super into the module it includes, 50 classes
n = 50
tag = "module Tag\n#{(0...n).map { |i| "  def t#{i} = \"t#{i}\"" }.join("\n")}\nend"
loud = "module Loud\n  include Tag\n#{(0...n).map { |i| "  def t#{i} = super.upcase" }.join("\n")}\nend"
File.write("big-50.rb", tag + "\n" + loud + "\n" + (0...50).map { |i| "class C#{i}\n  include Loud\nend" }.join("\n") + "\np C0.new.t0\np C49.new.t#{n - 1}\n")
