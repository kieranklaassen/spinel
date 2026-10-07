# A block belongs to the frame it is written in, wherever it runs. A program
# where a block that may run elsewhere reads or sets `$~` keeps one set of
# registers, as before: a method that matches in a `when` arm or through a
# quantifier saves no frame there, and the block's match is its writer's.
def arm(v)
  case v when /a(.)/ then 1 end
  proc { $1 }
end

p arm("ab").call

def runs(v, pr)
  r = case v when /a/ then 1 else 2 end
  pr.call
  r
end

pr = proc { "k9" =~ /k(\d)/ }
p runs("a", pr)
p $1

class Scan
  def on(&b) = @b = b

  def feed(v)
    k = case v when /\d/ then :num else :word end
    @b.call(v)
    k
  end
end

s = Scan.new
s.on { |v| v =~ /(\d)x/ }
p s.feed("7x")
p $1

def any_then(a, pr)
  r = a.any?(/b/)
  pr.call
  r
end

p any_then(["ab"], lambda { "m3" =~ /m(\d)/ })
p $1
