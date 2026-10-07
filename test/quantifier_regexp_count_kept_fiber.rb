f = Fiber.new do
  r = ["xb", "q"].any?(/(.)b/)
  Fiber.yield r
  1
end
p f.resume
p $~
