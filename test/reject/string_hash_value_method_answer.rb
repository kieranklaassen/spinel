# The Hash is a method's answer: its stores are that method's.
def build; h = {}; h[:a] = +"q"; h; end
g = build
g.each_value { |x| x << "!" }
p g
