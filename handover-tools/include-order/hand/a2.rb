module A; def who = "A"; end
module B
  include A
  def setup
    def who = "B"
  end
end
class C; include B; include A; end
p C.new.who
