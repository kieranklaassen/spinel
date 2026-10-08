module A; def who = "A"; end
module B; include A; def who = "B"; end
class C
  include B
  class << self
    def make = new
  end
  include A
end
p C.make.who
