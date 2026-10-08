# An exception object that nothing rescues prints its whole message, a NUL in
# it too. Its line stopped at the NUL: the object's message went there as a C
# string. stderr goes to a file here, so the program can read back the line of
# each at_exit hook that raised.
require "tmpdir"

class OwnError < StandardError
  def initialize(what)
    super("own\0" + what)
  end
end

def again
  yield
rescue TypeError => e
  raise e
end

path = File.join(Dir.tmpdir, "sp_uncaught_exception_object_message_nul_#{Process.pid}.txt")
at_exit do   # registered first, so it runs last
  STDERR.flush
  err = File.binread(path)
  File.delete(path)
  ["no nul (RuntimeError)", "left\0right (TypeError)", "made\0first (IOError)",
   "own\0error (OwnError)", "raised\0again (TypeError)", "in a\0fiber (KeyError)",
   "\0leading (IndexError)", "trailing\0 (IndexError)"].each do |line|
    p err.include?(line + "\n")
  end
  # no NUL, but the six bytes a message with one is marked with inside the runtime
  p err.include?("\xFF\xFECM\xFD\x01AAAA rest (RuntimeError)\n".b)
  # and a whole message of that form: its bytes are the message
  p err.include?("\xFF\xFECM\xFD\x01\x05\x00\x00\x00hello (ArgumentError)\n".b)
  p err.include?("\xFF\xFECM\xFD\x01\x05\x00\x00\x00he\0lo (KeyError)\n".b)
  p err.include?(LARGE + " (IOError)\n".b)
  # the form a frozen String's message is marked with differs in the sixth byte
  p err.include?("\xFF\xFECM\xFD\x02AAAA rest (NameError)\n".b)
  p err.include?(FROZEN_LARGE + " (EOFError)\n".b)
end
at_exit { raise RuntimeError.new("no nul") }
at_exit { raise TypeError.new("left" + "\0right") }
made = IOError.new("made\0first")
at_exit { raise made }
at_exit { raise OwnError.new("error") }
at_exit { again { raise TypeError, "raised\0again" } }
at_exit { Fiber.new { raise KeyError.new("in a\0fiber") }.resume }
at_exit { raise IndexError.new("\0leading") }
at_exit { raise IndexError.new("trailing\0") }
at_exit { raise RuntimeError.new("\xFF\xFECM\xFD\x01AAAA rest".b) }
at_exit { raise ArgumentError.new("\xFF\xFECM\xFD\x01\x05\x00\x00\x00hello".b) }
at_exit { raise KeyError.new("\xFF\xFECM\xFD\x01\x05\x00\x00\x00he\0lo".b) }
# the same with no NUL anywhere: each byte of its length is 1
LARGE = "\xFF\xFECM\xFD\x01\x01\x01\x01\x01".b + "x" * 16_843_009
at_exit { raise IOError.new(LARGE) }
at_exit { raise NameError.new("\xFF\xFECM\xFD\x02AAAA rest".b) }
FROZEN_LARGE = "\xFF\xFECM\xFD\x02\x01\x01\x01\x01".b + "x" * 16_843_009
at_exit { raise EOFError.new(FROZEN_LARGE) }

begin
  raise TypeError.new("rescued\0here")
rescue TypeError => e
  p e.message.bytes.size   # for contrast: right before as well
end
STDERR.reopen(path, "w")
