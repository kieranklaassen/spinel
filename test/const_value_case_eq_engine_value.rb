# A test of the engine picks the value: CRuby binds the constant in the arm
# this compiler drops, so `K === x` is not asked of the value that is left.
if RUBY_ENGINE == "ruby"
  LIMIT = 6..9
else
  LIMIT = 1..5
end
p(LIMIT === 3)

NAME = "abc"
unless RUBY_ENGINE == "spinel"
  Object.class_eval { remove_const("NA" + "ME") }
  NAME = "xyz"
end
p(NAME === "abc")

class Gate
  if defined?(RubyVM)
    CODE = 16
  end
  CODE = 15 unless defined?(RubyVM)
  def ok?(n) = CODE === n
end
p(Gate.new.ok?(15))
