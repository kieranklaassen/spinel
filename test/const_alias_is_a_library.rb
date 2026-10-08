# A class under a library's class reads the library's constants before the
# program's own level: Socket::Option here, not the program's Option.
require "socket"
Option = String
class Conn < Socket
  def self.opt?(v) = v.is_a?(Option)
end
p Conn.opt?("s")
p "s".is_a?(Option)
