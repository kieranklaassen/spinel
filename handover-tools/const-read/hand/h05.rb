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
module Mix
  class Base
    LIMIT = "mix base"
  end
end
class Base
  include M2
  include M5
end
module NS
  include Mix
  class C < Base
    def lim = LIMIT
  end
end
p NS::C.new.lim
