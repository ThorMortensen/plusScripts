
require_relative 'manduca.rb'


cli = Manduca.new(promtMsg: "Please write here --> ".green.bold,
                  defaultAnswer: "This is default!",
                  # defaultAnswerLastInput: true,
                  # useDefaultOnEnter: true,
                  historyFileName: "manduca-test2"
                  )


answ = "foo"
while answ != "q"
  answ = cli.prompt
  # puts
  puts "result was: |#{answ}|"
  cli.saveInputStr unless answ == "q"
end
