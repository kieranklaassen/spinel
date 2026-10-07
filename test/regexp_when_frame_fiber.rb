# A method suspended in a Fiber keeps its frame while other code runs, and
# `$~` is not kept per Fiber. A program that runs a Fiber keeps one set of
# registers, as before: what the main program matched while the method was
# suspended stays.
def waits(v)
  k = case v when /f(.)/ then 1 else 2 end
  Fiber.yield k
  7
end

f = Fiber.new { waits("f4") }
p f.resume
"k5" =~ /k(\d)/
p f.resume
p $1
