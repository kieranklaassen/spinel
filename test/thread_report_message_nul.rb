# The report of a thread that dies of its exception prints a message that holds
# a NUL whole. It went out as the six bytes that mark such a message inside the
# runtime, and none of the text. stderr goes to a file here, so the program can
# read the report back; it waits for the line, since a join may return before
# the report is written.
def reported?(path, line)
  200.times do
    STDERR.flush
    return true if File.binread(path).include?(line)
    sleep 0.01
  end
  false
end

path = "/tmp/sp_thread_report_message_nul_#{Process.pid}.txt"
STDERR.reopen(path, "w")
t = Thread.new { raise ArgumentError, "in a\0thread" }
begin
  t.join
rescue ArgumentError => e
  p e.message.bytes.size   # for contrast: right before as well
end
u = Thread.new { raise ArgumentError, "no nul" }
begin
  u.join
rescue ArgumentError
end
p reported?(path, "in a\0thread (ArgumentError)\n")
p reported?(path, "no nul (ArgumentError)\n")
File.delete(path)
