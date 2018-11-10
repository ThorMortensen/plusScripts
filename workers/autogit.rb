#   Auther  : thm
#   Date    : 25-October-2017
#   File    : autogit.rb
#   Project : scripts


require_relative 'rubyHelpers.rb'
require 'net/http'
require 'uri'
require 'json'
require 'yaml'


@homePath = `echo $HOME` #ARGV[0]
@homePath["\n"] = ""

SCRIPTS_FOLDER_PATH = File.dirname(__FILE__)

AUTO_COMMIT_PATHS = "AUTO_COMMIT_PATHS"
AUTO_ADD_PATHS = "AUTO_ADD_PATHS"


def exitPoint
  puts "\nEnjoy life. Enjoy QOL scripts.".green
  exit()
end

# @param [string] repoName
# @param [string] githubUsername
# @param [string] githubToken
# @return [Net::Net::HTTP]
def makeGithubRepo(repoName, githubUsername, githubToken)
  uri = URI.parse('https://api.github.com/user/repos')
  request = Net::HTTP::Post.new(uri)
  request.basic_auth(githubUsername, githubToken)
  request.body = JSON.dump("name" => "#{repoName}")

  req_options = {use_ssl: uri.scheme == 'https'}

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  return response

end


def makeRemoteGitRepo

  begin

    userInfo = YAML.load_file("#{SCRIPTS_FOLDER_PATH}/GITHUB_SETTINGS.yml")

  rescue SystemCallError
    puts 'No "GITHUB_SETTINGS.yml" file found'.red
    puts 'make one now? [Y/n]'.bg_magenta.black
    if gets()[/[^n]/]
      puts 'Now creating the "GITHUB_SETTINGS.yml" that should not be shared!'.yellow
      puts 'MAKE SURE "GITHUB_SETTINGS.yml" IS IN .gitignore OR THE TOKEN WILL BE REVOKED'.yellow
      puts
      puts "Please enter your Github #{'Username'.bold.black} ".bg_magenta.black
      print '~> '
      userInputEmail = gets
      puts "Please enter your Github access #{'Token'.bold} ".bg_magenta.black
      puts "See:"
      puts "  https://github.com/blog/1509-personal-api-tokens".gray
      puts
      print '~> '
      userInputToken = gets

      File.write("#{SCRIPTS_FOLDER_PATH}/GITHUB_SETTINGS.yml",
                 "GITHUB_ACCESS_TOKEN: #{userInputToken}\nGITHUB_USERNAME: #{userInputEmail}")
    end
  end

  githubUsername = userInputEmail || userInfo["GITHUB_USERNAME"]
  githubToken = userInputToken || userInfo["GITHUB_ACCESS_TOKEN"]

  newRemoteRepoName = Dir.pwd
  newRemoteRepoName = newRemoteRepoName.split("/").last

  puts "Remote repo will get this name: ".bg_magenta.black
  puts
  puts "  #{newRemoteRepoName}".bold
  puts
  puts "Enter another name OR leave empty".bg_magenta.black
  print "~> "
  userInput = gets

  userInput["\n"] = ""

  newRemoteRepoName = userInput unless userInput.empty?

  puts "Creating remote repo".cyan

  remoteRepoFailed = true
  abortRepoCration = false

  while remoteRepoFailed

    response = makeGithubRepo(newRemoteRepoName, githubUsername, githubToken)
    respBody = JSON.parse(response.body)

    if response.code == "422"
      puts "Remote #{respBody["message"]}".red
      puts "Remote repo name \"#{newRemoteRepoName.bold}\" may already be in use.".bg_magenta.black
      puts "Try another name OR leave empty to skip remote repo creation".bg_magenta.black
      print "~> "
      newRemoteRepoName = gets
      newRemoteRepoName["\n"] = ""
      if newRemoteRepoName.empty?
        puts "Aborting remote repo creation".cyan
        abortRepoCration = true
        break
      end
      next
    end

    remoteRepoFailed = false

  end

  unless abortRepoCration
    puts "Remote repo was successfully created. It can be found here: ".green
    puts
    puts "  #{respBody["html_url"]}"
    puts
  end

  return respBody["ssh_url"]
end


def createGitRepo

  puts "Auto make remote repo? [Y/n]".bg_blue.black

  userSays = gets()

  if userSays[/^\n/]
    remote = makeRemoteGitRepo
  end

  if userSays['n'] or remote.nil? or remote.empty?

    puts "Add remote repo OR leave empty for local repo only".bg_blue.black
    print "~> "
    remote = gets.chomp
    unless remote.empty?
      remote = "#{remote}"
      puts
      puts "Remote repo is correct?".bg_blue.black
      puts
      puts "#{remote}".bold
      puts
      print "[Y/n] "
      if gets()['n']
        exitPoint()
      end
    end

  end

  puts "Creating new git repo:".cyan
  puts `git init && git add . && git commit -m "initial commit"`.gray

  unless remote.empty?
    puts "Linking repo to remote:".cyan
    puts `git remote add origin #{remote} && git push -u origin master`.gray
  end

  return Dir.pwd

end

def homeToTilde(path)
  return path.gsub(@homePath, "~")
end

def tildeToHome(path)
  return path.gsub("~", @homePath)
end

def checkForGitRepo

  gitBasePath = `git rev-parse --show-toplevel`

  if gitBasePath.empty?
    puts "No git repo found.".red
    puts "Make one now? [Y/n]".bg_brown.black
    if gets['n']
      exitPoint()
    end
    gitBasePath = createGitRepo()
  else
    gitBasePath["\n"] = ""
  end

  return homeToTilde(gitBasePath)

end

def getCurrentPaths
  autogitPathYaml = "#{SCRIPTS_FOLDER_PATH}/autogit_paths.yml"
  return YAML.load_file(autogitPathYaml)
end

def setNewPaths(newPaths)
  autogitPathYaml = "#{SCRIPTS_FOLDER_PATH}/autogit_paths.yml"
  File.open(autogitPathYaml, 'w') {|f| YAML.dump(newPaths, f)}
end

def gotoNewDir(dir, stopOnFail = true)

  begin
    Dir.chdir dir
  rescue SystemCallError
    puts "Input path \"#{dir.bold}\" not valid".red
    exitPoint if stopOnFail
  end

  return Dir.pwd

end

# @param [string] arg1
# @param [string] arg2
# @return [string]
def autogit_add(arg1 = nil, arg2 = nil)

  pathsToModefy = AUTO_COMMIT_PATHS
  mode = 'autogit'

  newAutogitPath = homeToTilde(Dir.pwd)

  unless arg1.nil?
    if arg1 == '-a'
      mode = :'autogit-add'
      pathsToModefy = AUTO_ADD_PATHS
    else
      newAutogitPath = homeToTilde(gotoNewDir(arg1))
    end
  end

  unless arg2.nil?
    if arg2 == '-a'
      mode = :'autogit-add'
      pathsToModefy = AUTO_ADD_PATHS
    else
      newAutogitPath = homeToTilde(gotoNewDir(arg1))
    end
  end

  paths = getCurrentPaths

  if mode == 'autogit'
    newAutogitPath = checkForGitRepo
  else
    if paths[AUTO_COMMIT_PATHS].nil? or !paths[AUTO_COMMIT_PATHS].include? newAutogitPath
      puts "Path is currently not in autogit. It make no sense to include it in autogit-add".red
      puts "Add to autogit? [Y/n]".bg_brown.black
      if gets['n']
        exitPoint()
      end
      newAutogitPath = autogit_add
      paths = getCurrentPaths
    end
  end

  if paths[pathsToModefy].nil?
    paths[pathsToModefy] = [newAutogitPath]
  elsif paths[pathsToModefy].include? newAutogitPath
    puts "Path already added to #{mode}".red
    exitPoint
  else
    paths[pathsToModefy].push(newAutogitPath)
  end

  setNewPaths(paths)

  puts "Path \"#{newAutogitPath.bold}\" successfully added to #{mode} ".green

  return newAutogitPath
end

# @param [string] arg1
# @param [string] arg2
def autogit_remove(arg1 = nil, arg2 = nil)

  pathsToModefy = AUTO_COMMIT_PATHS
  mode = 'autogit'


  unless arg1.nil?
    if arg1 == '-a'
      mode = :'autogit-add'
      pathsToModefy = AUTO_ADD_PATHS
      arg1 = nil
    else
      gotoNewDir(arg1)
    end
  end

  unless arg2.nil?
    if arg2 == '-a'
      mode = :'autogit-add'
      pathsToModefy = AUTO_ADD_PATHS
    else
      arg1 = nil
      gotoNewDir(arg2)
    end
  end

  pathToRemove = homeToTilde(arg1 || Dir.pwd)
  paths = getCurrentPaths

  if paths[pathsToModefy].nil? or not paths[pathsToModefy].delete(pathToRemove)
    puts "Path \"#{pathToRemove.bold}\" is currently not in #{mode}".green
  else
    puts "Path \"#{pathToRemove.bold}\" successfully removed from #{mode}".green
  end

  setNewPaths(paths)

end

def autogitCommitAndPush

  paths = getCurrentPaths

  if paths[AUTO_COMMIT_PATHS].nil? or paths[AUTO_COMMIT_PATHS].length == 0
    puts 'No paths in autogit. Use +autogit_add to get started'
    exitPoint
  end


  paths[AUTO_COMMIT_PATHS].each {|path|

    pathToGit = tildeToHome(path)

    begin
      Dir.chdir pathToGit
    rescue SystemCallError
      puts "Autogit path \"#{pathToGit}\" not valid.".gray
      next
    end

    if paths[AUTO_ADD_PATHS].include? path
      puts "Adding all new files to git ~~> #{pathToGit}".black.bg_yell
      puts `git add . `
    end

    puts "Commit and push ~~> #{pathToGit}".black.bg_green

    gitStatus = `git commit -a -m "This is not a message (lazy commit)"`

    if gitStatus.empty?
      puts "Autogit path \"#{pathToGit}\" has no git repo".red
      puts 'Make repo via git or use +autogit_add'.cyan
      next
    else
      puts gitStatus
    end

    puts `git push`
  }

  exitPoint
end

def autogitPull

  paths = getCurrentPaths

  if paths[AUTO_COMMIT_PATHS].nil?
    puts 'No paths in autogit. Use +autogit_add to get started'
    exitPoint
  end

  paths[AUTO_COMMIT_PATHS].each {|path|
    pathToGit = tildeToHome(path)
    begin
      Dir.chdir pathToGit
    rescue SystemCallError
      puts "Input path \"#{pathToGit}\" not valid.".gray
      next
    end
    puts "Pull ~~> #{pathToGit.bold.black}".black.bg_green
    remoteStatus = `git pull`
    if remoteStatus.empty?
      puts 'No remote repo for this entry'.red
      puts 'Add remote repo via git or use +autogit_add to add remote support'.cyan
    else
      puts remoteStatus
    end
  }

  exitPoint
end


################################################
#               MAIN
################################################

runMode = ARGV[0]
arg1 = ARGV[1]
arg2 = ARGV[2]
ARGV.clear


case runMode
  when 'add'
    autogit_add(arg1, arg2)

  when 'remove'
    autogit_remove(arg1, arg2)

  when 'pull'
    autogitPull

  else
    autogitCommitAndPush

end
exitPoint
