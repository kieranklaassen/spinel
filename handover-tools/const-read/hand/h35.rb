module M0
  LIMIT = [1, 2].freeze
  OPTS = { a: 1 }.freeze
end
module M1
  LIMIT = %w[a b].freeze
  OPTS = { b: 2 }.freeze
end
module M2
  include M0
  include M1
end
module M5
  include M0
end
class R
  include M2
  include M5
  def lim = LIMIT
  def opts = OPTS
end
p R.new.lim
p R.new.opts
