# A program that takes one of Exception's names away from a class: what
# respond_to? answers for an exception is left as it was. Here the object is
# of a subclass that made `message` private, rescued as its parent.
class MyErr < StandardError; end
class Shy < MyErr
  private :message
end
class Gone < MyErr
  undef_method :message
end

[Shy, Gone].each do |k|
  begin
    raise k, "q"
  rescue MyErr => e
    p e.respond_to?(:message)
  end
end
p Shy.new("s").respond_to?(:message), Gone.new("g").respond_to?(:message)
