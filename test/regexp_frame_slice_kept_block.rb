# A block belongs to the frame it is written in, wherever it runs. A program
# where a block that may run elsewhere sets `$~` keeps one set of registers,
# as before: a method that matches through slice! or a pattern of `in` saves
# no frame there, and the block's match is its writer's.
def cut_then(s, pr)
  r = s.slice!(/(b)/)
  pr.call
  r
end

pr = proc { "k9" =~ /k(\d)/ }
p cut_then(+"abc", pr)
p $1

def kind_then(s, pr)
  k = case s
      in /a(b)/ then 1
      else 2
      end
  pr.call
  k
end

p kind_then("ab", lambda { "m3" =~ /m(\d)/ })
p $1
