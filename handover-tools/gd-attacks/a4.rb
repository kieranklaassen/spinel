module M0; class Error < StandardError; end; end
module M1; class Error < StandardError; end; end
module M2; include M0; include M1; end
module M5; include M0; end
class R
  include M2
  include M5
  def mine?(e) = e.is_a?(Error)
end
[M0::Error, M1::Error].each do |k|
  begin
    raise k, "x"
  rescue => e
    p R.new.mine?(e)
  end
end
