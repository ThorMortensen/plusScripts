
def mVoltToDcdcLevel mV 
  tv = ((mV * (((2**18) - 1)  * 2 )) / 165000)
  return (tv >> 1) + (tv & 1) >> 10
end 

level = Array.new(3)

for i in 0..2 do  
  if ARGV.length < 3 
    puts "Please enter mV value for level#{i+1}"
    mV = gets
    level[i] = mVoltToDcdcLevel mV.to_i
    puts
  else 
    level[i] = mVoltToDcdcLevel ARGV[i].to_i
  end 
  puts "level#{i+1} #{level[i]}"

end
combined = (level[2] << 16) | (level[1] << 8) | (level[0] << 0)
puts
puts "Write to dcdc_level register (hex)   \e[1m#{combined.to_i.to_s(16)}\e[0m "


