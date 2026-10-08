module Net
  class Error < StandardError; end
end
class Conn
  Error = Class.new(StandardError)
  def t(e) = e.is_a?(Error)
end
begin
  raise Net::Error, "x"
rescue => e
  p Conn.new.t(e)
end
