require 'tty'
require_relative 'rubyHelpers.rb'
require_relative 'manduca.rb'


# puts "ARGV[0]: #{ARGV[0]}"
# puts "ARGV[1]: #{ARGV[1]}"
# puts "ARGV[2]: #{ARGV[2]}"
# puts "ARGV.length: #{ARGV.length}"

# ARGV.clear

metricPrefix = {
  "T" => 10**12,
  "G" => 10**9,
  "M" => 10**6,
  "k" => 10**3,
  "b" => 1,
  ################
  "m" => 10**-3,
  "u" => 10**-6,
  "n" => 10**-9,
}

metricNammes = {
  "T" => "tera",
  "G" => "giga",
  "M" => "mega",
  "k" => "kilo",
  "b" => "base",
  ################
  "m" => "milli",
  "u" => "micro",
  "n" => "nano",
}


def errorExit
  puts "Invalid argument. Use \"+convert <number><unit> <to unit>\""
  exit
end


def ac from, to, number


end

begin

  sift = ARGV[0].match(/(\d+,?\.?\d?)\s?(\D)/i)

  if ARGV.length == 3
    number = ARGV[0].to_f
    from = ARGV[1][0]
    to = ARGV[2][0]
  else
    number = sift[1].to_f
    from = sift[2]
    to = ARGV[1][0]
  end

  puts "#{number} #{metricNammes[from]} --> #{(number * metricPrefix[from] / metricPrefix[to]).to_f} #{metricNammes[to]}"

rescue
  errorExit
end









