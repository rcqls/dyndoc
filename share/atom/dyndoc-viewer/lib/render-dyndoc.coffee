exports.eval = (text='', filePath, callback) ->

	decode_cmd = (cmd) ->
	  regexp = /^__send_cmd__\[\[([a-zA-Z0-9_]*)\]\]__([\s\S]*)/m
	  res = cmd.match(regexp)
	  {"cmd": res[1], "content": res[2]}

	end_token = "__[[END_TOKEN]]__"

	net = require 'net'
	client = net.connect {port: 7777, host: 'localhost'}, () ->
		client.write '__send_cmd__[[dyndoc]]__' + text + end_token + '\n'

		client.on 'data', (data) ->
			#console.log(data.toString())
			data.toString().split(end_token).slice(0,-1).map (cmd) ->
				#console.log("<<"+cmd+">>")
				resCmd = decode_cmd(cmd)
				if resCmd["cmd"] != "windows_platform"
						#console.log("data: "+resCmd["content"])
						callback(null, resCmd["content"])
						client.end()
				resCmd

	  client.on 'error', (err) ->
	    #console.log('error:', err.message)
	    callback error,err.message
