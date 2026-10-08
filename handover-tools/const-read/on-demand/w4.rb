module Slow
  LIMIT = 1
end
module Fast
  LIMIT = 2
end
module Tuned
  include Slow
  include Fast
end
module Logged
  include Slow
end
module M0
  include Tuned
  include Logged
end
module M1
  include M0
end
module M2
  include M1
end
module M3
  include M2
end
module M4
  include M3
end
module M5
  include M4
end
module M6
  include M5
end
module M7
  include M6
end
module M8
  include M7
end
module M9
  include M8
end
module M10
  include M9
end
module M11
  include M10
end
module M12
  include M11
end
module M13
  include M12
end
module M14
  include M13
end
module M15
  include M14
end
module M16
  include M15
end
module M17
  include M16
end
module M18
  include M17
end
module M19
  include M18
end
module M20
  include M19
end
module M21
  include M20
end
module M22
  include M21
end
module M23
  include M22
end
module M24
  include M23
end
module M25
  include M24
end
module M26
  include M25
end
module M27
  include M26
end
module M28
  include M27
end
module M29
  include M28
end
module M30
  include M29
end
module M31
  include M30
end
module M32
  include M31
end
module M33
  include M32
end
module M34
  include M33
end
module M35
  include M34
end
module M36
  include M35
end
class Job
  include M20
  def limit = LIMIT
end
p Job.new.limit
