module M0
  LIMIT = 1
end
module M1
  LIMIT = 2
end
module M2
  include M0
  include M1
end
module M5
  include M0
end
LIMIT = 0
class R
  include M2
  include M5
  class << self
    def slim = LIMIT
  end
end
p R.slim
