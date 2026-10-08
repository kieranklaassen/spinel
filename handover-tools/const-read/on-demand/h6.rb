module P
  module Defaults
    class Box; def v = 1; end
  end
  class Base
    include Defaults
    class Box; def v = 2; end
  end
  class Worker < Base
    include Defaults
    def box = Box.new.v
  end
end
module Q
  class Base
    class Box; def v = 5; end
  end
end
p P::Worker.new.box
