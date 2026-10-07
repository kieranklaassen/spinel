module Lib
  class SumState < StandardError; end
end
begin
  raise Lib::SumState, "x"
rescue => e
  p e.class
end
