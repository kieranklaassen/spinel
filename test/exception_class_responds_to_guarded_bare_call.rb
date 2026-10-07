# A method of an exception class that calls `message` with no receiver
# behind respond_to?: the answer is left as it was, and the call is not
# reached.
class MyErr < StandardError
  def log_it
    message if self.respond_to?(:message)
    puts "logged"
  end
end
MyErr.new("q").log_it
