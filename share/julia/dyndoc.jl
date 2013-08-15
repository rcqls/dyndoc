#cmd="a=1\n(a)\nfor i in 1:3\nprintln(i)\nend"

function capture_cmd(cmd::String)
	add,cmd0=true,String[]
	res=Any[] #Dict{String,Any}()
	for l=split(cmd,"\n")
		#println("l => ",l)
		push!(cmd0,l) 
		pcmd0=Base.parse_input_line(join(cmd0,"\n"))
		#print(join(cmd0,"\n")*":");println(pcmd0)
		add = typeof(pcmd0)==Expr && pcmd0.head == :continue
		if !add 
			#print("ici:")
			#println(Base.eval(pcmd0))
			push!(res,(join(cmd0,"\n"),eval(pcmd0))) 
			cmd0=String[] 
		end
		#println(res)
	end
	res
end

function get_stdout_iobuffer()
	seek(STDOUT, 0)
	jl4rb_out = takebuf_string(STDOUT)
	truncate(STDOUT, 0)
	jl4rb_out
end

function get_stderr_iobuffer()
	seek(STDERR, 0)
	jl4rb_out = takebuf_string(STDERR)
	truncate(STDERR, 0)
	jl4rb_out
end

# export weave

# module DyndocSandbox
#     # Copied from Gadfly.jl/src/weave.jl 
#     # Replace OUTPUT_STREAM references so we can capture output.
#     OUTPUT_STREAM = IOString()
#     print(x) = Base.print(OUTPUT_STREAM, x)
#     println(x) = Base.println(OUTPUT_STREAM, x)

#     function eval(expr)
#     	result = try 
#             Base.eval(DyndocSandbox, expr)
#             seek(DyndocSandbox.OUTPUT_STREAM, 0)
#         	output = takebuf_string(DyndocSandbox.OUTPUT_STREAM)
#         	truncate(DyndocSandbox.OUTPUT_STREAM, 0)
#         	output
#         catch e
#             io = IOBuffer()
#             print(io, "ERROR: ")
#             Base.error_show(io, e)
#             tmp = bytestring(io)
#             close(io)
#             tmp
#         end
#         result
#     end
# end

function capture_julia(cmd::String)
	add,cmd0=true,String[]
	res=Any[] #Dict{String,Any}()
	for l=split(cmd,"\n")
		#println("l => ",l)
		push!(cmd0,l) 
		pcmd0=Base.parse_input_line(join(cmd0,"\n"))
		#print(join(cmd0,"\n")*":");println(pcmd0)
		add = typeof(pcmd0)==Expr && pcmd0.head == :continue
		if !add 
			#print("ici:")
			#println(Base.eval(pcmd0))
			result,error = "","" 
			try 
				result=eval(pcmd0)
			catch e
	            io = IOBuffer()
	            print(io, "ERROR: ")
	            Base.error_show(io, e)
	            error = bytestring(io)
	            close(io)
	        end
			push!(res,(join(cmd0,"\n"),string(result),get_stdout_iobuffer(),error,get_stderr_iobuffer())) 
			cmd0=String[] 
		end
		#println(res)
	end
	res
end