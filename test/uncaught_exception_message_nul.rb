# An uncaught exception whose message holds a NUL prints the whole message, as
# e.message gives it. Its line went out as the six bytes that mark such a
# message inside the runtime, and none of the text. stderr goes to a file here,
# so the program can read back the line of each at_exit hook that raised.
def cleanup
  yield
ensure
  puts "ensure"
end

def work
  cleanup { raise ArgumentError, "past an\0ensure" }
rescue KeyError
  puts "not reached"
end

path = "/tmp/sp_uncaught_exception_message_nul_#{Process.pid}.txt"
at_exit do   # registered first, so it runs last
  STDERR.flush
  err = File.binread(path)
  File.delete(path)
  ["no nul (RuntimeError)", "plain\0text (RuntimeError)", "\0leading (IOError)",
   "trailing\0 (IOError)", "in a\0fiber (TypeError)", "in a\0lock (KeyError)",
   "raised\0again (IndexError)", "built n\0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 42 (ArgumentError)",
   "past an\0ensure (ArgumentError)"].each do |line|
    p err.include?(line + "\n")
  end
end
at_exit { raise "no nul" }
at_exit { raise "plain\0text" }
at_exit { raise IOError, "\0leading" }
at_exit { raise IOError, "trailing\0" }
at_exit { Fiber.new { raise TypeError, "in a\0fiber" }.resume }
at_exit { Mutex.new.synchronize { raise KeyError, "in a\0lock" } }
at_exit do
  begin
    raise IndexError, "raised\0again"
  rescue IndexError
    raise
  end
end
x = "n\0" + "x" * 40
at_exit { raise ArgumentError, "built #{x} #{x.size}" }
at_exit { work }

begin
  raise ArgumentError, "rescued\0here"
rescue ArgumentError => e
  p e.message.bytes.size   # for contrast: right before as well
end
STDERR.reopen(path, "w")
