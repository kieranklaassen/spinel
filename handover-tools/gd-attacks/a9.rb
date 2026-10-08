module App
  module Net
    class Error < StandardError; end
  end
  module Disk
    class Error < StandardError; end
  end
  def self.q(e) = [e.is_a?(Net::Error), e.is_a?(Disk::Error), e.is_a?(App::Net::Error)]
end
[App::Net::Error, App::Disk::Error].each do |k|
  begin
    raise k, "x"
  rescue => e
    p App.q(e), e.is_a?(App::Net::Error)
  end
end
