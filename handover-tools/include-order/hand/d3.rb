module Y; def who = "Y"; end
module Z; def who = "Z"; end
module K1; include Y; include Z; end
module K2; include Y; end
module M; include K1; include K2; end
class C
  include Z
  include Y
  include M
  alias other who
end
p C.new.who
