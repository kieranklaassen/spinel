# `puts` is the program's `keep` under another name.
def keep(x)
  $k = x
  nil
end
alias puts keep
a = ["q"]
puts a
$k << +"s"
a.find { |s| s == "s" } << "!"
p a
