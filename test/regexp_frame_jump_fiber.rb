# A method suspended in a Fiber keeps its frame while other code runs. `$~` is
# not kept per Fiber, so a program that runs a Fiber leaves the registers as
# they are when a raise leaves a method: what the main program matched while
# the method was suspended stays.
def waits(s)
  s =~ /f(.)/
  Fiber.yield 1
  raise ArgumentError, "x"
end

f = Fiber.new do
  begin
    waits("f4")
  rescue ArgumentError
  end
  7
end
f.resume
"k5" =~ /k(\d)/
p f.resume
p $1
