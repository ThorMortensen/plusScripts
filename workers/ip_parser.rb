require 'yaml'


SCRIPTS_FOLDER_PATH = File.dirname(__FILE__)


def getActiveDevice(device)
  ipCollection = YAML.load_file("#{SCRIPTS_FOLDER_PATH}/ip_addresses.yml")
  return ipCollection[device]
end

device = ARGV[0]
cmd = ARGV[1]
ipId = ARGV[2]
ARGV.clear

devices = {'masc' => '192.168.52.',
           'slp' => '192.168.51.'}


case cmd
  when 'setActive'
    ips = YAML.load_file("#{SCRIPTS_FOLDER_PATH}/ip_addresses.yml")
    ips[device][0] = devices[device] + ipId
    File.open("#{SCRIPTS_FOLDER_PATH}/ip_addresses.yml", 'w') {|f| YAML.dump(ips, f)}

  when 'getActiveIP'
    puts YAML.load_file("#{SCRIPTS_FOLDER_PATH}/ip_addresses.yml")[device][0]

  when 'getActiveDev'
    activeIp = YAML.load_file("#{SCRIPTS_FOLDER_PATH}/ip_addresses.yml")[device][0]
    puts activeIp.to_s.split('.').last

  else

end
