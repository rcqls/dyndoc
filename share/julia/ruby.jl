

module Ruby

	librb=dlopen("libruby") 

	export start,stop,run

	function start()
		ccall(dlsym(librb,:ruby_init),Void,())
		ccall(dlsym(librb,:ruby_init_loadpath),Void,())
	end

	function stop()
		ccall(dlsym(librb,:ruby_finalize),Void,())
	end

	function run(code::String)
		state=1 #not modified then
		##println(code)
		res=ccall(dlsym(librb,:rb_eval_string_protect),Ptr{Uint64},(Ptr{Uint8},Ptr{Uint32}),bytestring(code),&state)
	 	return nothing
	end

end