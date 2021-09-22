require 'tty'
require 'tty-command'
require 'socket'
require_relative 'rubyHelpers.rb'
require_relative 'manduca.rb'



@cmd = TTY::Command.new printer: :null
@addr_infos = Socket.ip_address_list

@ipRegex = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.)\d{1,3}/

def scanIp(ipAddress)
  puts
  @spinner = TTY::Spinner.new("Scanning with \'nmap -sP #{ipAddress}/24\' ".brown + ":spinner".blue, format: :bouncing_ball)
  @spinner.auto_spin
  out, err = @cmd.run("nmap -sP #{ipAddress}/24", null: true)
  @spinner.stop('Done!'.green)
  ipUp         = out.scan(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
  latency      = out.scan(/\(.* latency\)/)
  name      = out.scan(/for(\s|.*) (\(|\d)/)

  thisFileName = ".fileDump/ipRange_#{ipAddress}"
  puts "Active hosts: #{ipUp.length} ".bold

  if File.exists?(thisFileName)
    oldIpUp = IO.readlines(thisFileName);
    oldIpUp.map {|x| x.chomp!}
  else
    ipUp.each_with_index do |ip, i|
      puts "Host is up #{ip} #{latency[i]}#{name[i][0]}"
    end

    File.open(thisFileName, "w+") do |dumpFile|
      dumpFile.puts(ipUp)
    end
    return
  end

  ipUp.each_with_index do |ip, i|
    if oldIpUp.delete(ip)
      puts "Host is up #{ip} #{latency[i]}" + "#{name[i][0]}"
    else
      puts "Host is up #{ip} #{latency[i]}".green + " NEW! ".green.bold + "(since last run)".gray + "#{name[i][0]}"
    end
  end


  if oldIpUp.length >= 1
    puts "\nMissing hosts: #{oldIpUp.length}".bold
    oldIpUp.each do |ip|
      puts "Host is down #{ip}".red + " Missing ".bold.red + "(since last run)".gray
    end
  end

  File.open(thisFileName, "w+") do |dumpFile|
    dumpFile.puts(ipUp)
  end

end


Dir.mkdir(".fileDump") unless File.exists?(".fileDump")


if ARGV[0].nil?

  simplePrompter = TTY::Prompt.new(interrupt: :signal)

  mode = simplePrompter.select("Select scan mode:", ["Default IP ranges", "Enter IP range"])
  cli = Manduca.new(promtMsg: "Please enter base ip range to scan ~> ".green.bold,
                    # defaultAnswer: "This is default!",
                    defaultAnswerLastInput: true,
                    # useDefaultOnEnter: true,
                    historyFileName: "ipScanHistory"
                    )

  if mode == "Enter IP range"
    rangeOk = true
    while rangeOk
      answ = cli.prompt
      if range = answ.match(/(\d{1,3}\.\d{1,3}\.\d{1,3}\.)\d{1,3}/)
        cli.saveInputStr
        scanIp(range[1] + '0')
      else
        puts "Not a valid ip!"
        rangeOk = false
      end
    end
    return 
  end



  @addr_infos.each do |ip|
    next if ip.ip_address == "127.0.0.1"
    if range = ip.ip_address.match(/(\d{1,3}\.\d{1,3}\.\d{1,3}\.)\d{1,3}/)
      scanIp(range[1] + '0')
      # (\d{1,3}\.\d{1,3}\.\d{1,3}\.)\d{1,3}
    end
  end
else

  if range = ARGV[0].match(/(\d{1,3}\.\d{1,3}\.\d{1,3}\.)\d{1,3}/)
    scanIp(range[1] + '0')
  else
    puts "Not a valid ip!"
  end

end
