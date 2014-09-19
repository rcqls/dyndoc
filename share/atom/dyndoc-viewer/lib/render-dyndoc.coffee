exports.eval = (text='', filePath, callback) ->

	decode_cmd = (cmd) ->
	  regexp = /^__send_cmd__\[\[([a-zA-Z0-9_]*)\]\]__([\s\S]*)/m
	  res = cmd.match(regexp)
	  {"cmd": res[1], "content": res[2]}

	end_token = "__[[END_TOKEN]]__"

	text=text.replace /\#\{/g,"__AROBAS_ATOM__{"

	net = require 'net'
	#util = require 'util'
	if atom.config.get 'dyndoc-viewer.localServer'
		host = atom.config.get 'dyndoc-viewer.localServerUrl'
		port = atom.config.get 'dyndoc-viewer.localServerPort'
	else
		host = atom.config.get 'dyndoc-viewer.remoteServerUrl'
		port = atom.config.get 'dyndoc-viewer.remoteServerPort'

	client = net.connect {port: port, host: host}, () ->
		#console.log (util.inspect '__send_cmd__[[dyndoc]]__' + text + end_token)
		client.write '__send_cmd__[[dyndoc]]__' + text + end_token + '\n'

		client.on 'data', (data) ->
			#console.log "data:" + data.toString()
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
