coffee = require 'coffee-script'
vm     = require 'vm'

module.exports =

  coffeeEval: (code) ->
    try
      output = vm.runInThisContext(coffee.compile(code, bare: true))
      console.log output
    catch e
      output = "Error:#{e}"
      console.error "Eval Error:", e

    output