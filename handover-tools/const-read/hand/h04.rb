module Helper
  LIMIT = "top helper"
end
module Other
  LIMIT = "other"
end
class P
  module Helper
    LIMIT = "nested helper"
  end
end
class C < P
  include Other
  include Helper
  include Other
  def lim = LIMIT
end
p C.new.lim
p C.ancestors.first(3)
