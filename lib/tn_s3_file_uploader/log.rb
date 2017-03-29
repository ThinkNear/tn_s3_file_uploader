class Log
  def self.log(str)
    puts "#{Time.now.strftime("%d/%m/%Y %H:%M:%S")} #{str}"
  end
end

