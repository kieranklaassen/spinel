class MyErr < SignalException; end
begin
  raise MyErr, "x"
rescue SignalException => e
  puts "rescued #{e.class}"
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end
