module Tag
  class Box; def v = 1; end
end
module P
  module Tag
    class Box; def v = 9; end
  end
  module Fast
    class Box; def v = 2; end
  end
  module Tuned
    include ::Tag
    include Fast
  end
  module Logged
    include ::Tag
  end
  class Shelf
    include Tuned
    include Logged
    def box = Box.new.v
  end
end
p P::Shelf.new.box
