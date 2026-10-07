module NS1
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
  class C
    include M2
    include M5
    def lim = LIMIT
  end
end
module NS2
  module M0
    LIMIT = 10
  end
  module M1
    LIMIT = 20
  end
  module M2
    include M1
    include M0
  end
  module M5
    include M1
  end
  class C
    include M2
    include M5
    def lim = LIMIT
  end
end
p NS1::C.new.lim
p NS2::C.new.lim
