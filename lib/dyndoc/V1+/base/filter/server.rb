module CqlsDoc

    VERB={:tex=>{
              :begin=>"\\begin{Verbatim}[frame=leftline,fontfamily=tt,fontshape=n,numbers=left]",
              :end=>"\\end{Verbatim}"
            },
	  		:ttm=>{
              :begin=>"\\begin{verbatim}",
              :end=>"\\end{verbatim}"
            },
            :txtl=>{
              :begin=>"<pre><code style=\"color:yellow\">",
              :end=>"</code></pre>"
            },
            :tm=>{
              :begin=>"<\\verbatim>__TM__",
              :end=>"__TM__</verbatim>"
            },
            :raw=>{
            	:begin=>"",
              	:end=>""
            }
          }
    VERB[:html]=VERB[:txtl]

   class RbServer

    @@start,@@stop="\\{","\\}"

    def RbServer.filter(str,rbEnvir=nil)
      res=str.gsub(/\\?(?i:\#Rb|\#rb|\:Rb|\:rb|\:)#{@@start}[^#{@@stop}]+#{@@stop}/) {|w|  
	  if w[0,1]=="\\"
	    w[1..-1]
	  else
	    k=(w[1,2].downcase=="rb" ? w[4..-2] : w[2..-2]) #the key
#p "apply:Rb";p k;p w;p rbEnvir
            RbServer.output(k,rbEnvir,:error=> w)
	  end
	}
      res
    end

=begin
    def RbServer.output(code,rbEnvir=nil,error="ERROR")
      begin
#puts "code";p code
	      out=eval(code,rbEnvir)
#puts "out";p out
      rescue
        out=error
      end
#p out
      out=out.join(",") if out.is_a? Array
      out.to_s
    end
=end

    def RbServer.output(code,rbEnvir=nil,opts={:error=>"ERROR"})

	    begin
	        if rbEnvir.is_a? Binding
		    	out=eval(code,rbEnvir)
		    elsif rbEnvir.is_a? Module
		        out=rbEnvir.module_eval(code)
		    end
	    rescue
			#two solution:
			#in the same spirit as #{}
			# out="\\:{"+code+"}"
			# or more informative for debugging!

			out="\\:{"+code+"}"
			
			if $dyndoc_ruby_debug and !$dyndoc_ruby_debug==:expression
	        	puts "WARNING: >>>>>>>>>>>>>>>>>>+\n"+opts[:error]+" in #{rbEnvir}:\n"+code+"\n<<<<<<<<<<<<<<<<<<" 
			end


			if $cfg_dyn and $cfg_dyn[:dyndoc_mode]!=:normal
	        	$dyn_logger.write("\nERROR Ruby:\n"+code+"\n")
	        end
			
	    rescue SyntaxError
	        puts "RbServer syntax error in: "+code
	        raise SystemError if $cfg_dyn[:dyndoc_mode]==:normal and  $dyndoc_ruby_debug
	        if $cfg_dyn and $cfg_dyn[:dyndoc_mode]!=:normal
	        	$dyn_logger.write("\nERROR Ruby Syntax:\n"+code+"\n")
	        end
	        out=":{"+code+"}"
	    end
#p out
      	out
    end

  end

  class RServer

  	require 'tempfile'

	def RServer.R4rb(mode,cli=nil) #mode= :R2rb or Rserve
		return unless [:R2rb,:Rserve].include? mode
		require 'R4rb'
		##puts "Rserver.R4rb: mode=#{mode}"
		Object.module_eval("R4rb_is #{mode}")
		##puts "Rserver.R4rb: R4rb";p Object.const_get(:R4rb)
		R4rb.init
		Rserve.client(cli) if cli
		##puts "Rserve.cli";p Rserve.cli
	end

	if $dyndoc_rserv
		##puts "$dyndoc_rserv";p $dyndoc_rserv 
		RServer.R4rb :Rserve,$dyndoc_rserv
		R4rb_status? if $dyndoc_server_hostname
	end

    def RServer.echo_verb(txt,mode,env="Global")
      txtout=CqlsDoc::RServer.echo(txt,env).strip
      mode=:default unless CqlsDoc::VERB.keys.include? mode
      header= (mode!=:default) and txtout.length>0
      out=""
      out << CqlsDoc::VERB[mode][:begin] << "\n" if header
      out << txtout
      out << "\n" << CqlsDoc::VERB[mode][:end] << "\n" if header
      out
    end

    def RServer.echo(block,env="Global")
      txtout=""
      optout=nil #options for the output
      hide=0
      passe=0
      opt = nil
      code="" 
      block.each_line{|l|
		l2=l.chomp
		inst=l2.delete(" ").split("|")[0]
		if inst
		  inst=inst.split(":")
		  ## number of lines to apply
		  nb = 1 #default
		  nb=inst[1].to_i if inst.length>1
		  ## instr to exec
		  inst=inst[0].downcase
		else
		  inst="line"
		end
		## options
		opt=l2.split("|")
		if opt.length>1
		  opt2=opt[1..-1]
		  ## of the form key=value like Hash
		  opt2.map!{|elt| elt.split("=")}
		  opt={}
		  opt2.each{|elt| opt[elt[0].downcase.delete(" ")]=elt[1]}
		else
		  opt=nil
		end
		case inst
		when "line"
		  txtout << "\n"
		when "##!eval"
		  passe= nb.to_i #this is a copy
		when "##out"
		  optout=opt
		when "##hide"
		  hide = nb.to_i
		else
		  txtout << ( code.length==0 ? "> " : "+ ") << l2 << "\n" if hide==0
		  if passe==0 and l2[0,1]!="#"
		    ## redirect R output
		    code << l << "\n" ##ajout de "\n" grace à Pierre (le 15/12/05) pour bug: "1:10 #toto" -> pas de sortie car parse erreur n2!!!
			case @@mode
	        when :capture_normal	    
		        evalOk=(R4rb <<  ".output<<-capture.output({"+RServer.code_envir(code,env)+"})")
	        when :capture_cqls
	        	evalOk=(R4rb <<  ".output<<-capture.output.cqls({"+RServer.code_envir(code,env)+"})")
	        end

		    ##Dyndoc.warn "evalOk",code,evalOk
		    if evalOk  
		     txt=(@@out < '.output' ) ##.join("\n").split(/\n/)
		     code="" 
		    else
		      txt=@@out=[]
		    end 
		    if optout and optout.keys.include? "short"
		      short=optout["short"].split(",")
		      short[0]=short[0].to_i
		      short[2]=short[2].to_i
		      (0...short[0]).each{|i| txtout << txt[i] << "\n"}
		      txtout << short[1] << "\n"
		      le = txt.length
		      ((le-short[2])...le).each{|i| txtout << txt[i] << "\n"}
		    else
		      txtout << txt.join("\n")
		      txtout += "\n" if @@out.length>0
		      ##txt.each{|l| txtout << l <<"\n"}
		    end
		  end
		  optout=nil 
		  hide -= 1 if hide>0
		  passe -=1 if passe>0
		end
      }
      return txtout
    end

    def RServer.echo_blocks(block,prompt={:normal=>'> ',:continue=>'+ '},env="Global")
      inputs,outputs=[],[]
      input,output="",""
      optout=nil #options for the output
      hide=0
      passe=0
      opt = nil
      code="" 
	  block.each_line{|l|
		l2=l.chomp
		inst=l2.delete(" ").split("|")[0]
		if inst
	  inst=inst.split(":")
	  ## number of lines to apply
	  nb = 1 #default
	  nb=inst[1].to_i if inst.length>1
	  ## instr to exec
	  inst=inst[0].downcase
	else
	  inst="line"
	end
	## options
	opt=l2.split("|")
	if opt.length>1
	  opt2=opt[1..-1]
	  ## of the form key=value like Hash
	  opt2.map!{|elt| elt.split("=")}
	  opt={}
	  opt2.each{|elt| opt[elt[0].downcase.delete(" ")]=elt[1]}
	else
	  opt=nil
	end
	case inst
	when "##!eval"
	  passe= nb.to_i #this is a copy
	when "##out"
	  optout=opt
	when "##hide"
	  hide = nb.to_i
	else
	  if hide==0
	    input << ( code.length==0 ? prompt[:normal] : prompt[:continue]) if prompt
	    input <<  l2 << "\n"
	  end
	  if passe==0 and l2[0,1]!="#"
	    ## redirect R output
	    code << l << "\n" ##ajout de "\n" grace à Pierre (le 15/12/05) pour bug: "1:10 #toto" -> pas de sortie car parse erreur n2!!!
	    evalOk=(R4rb <<  ".output<<-capture.output({"+RServer.code_envir(code,env)+"})")
	    if evalOk  
	     txt=(@@out < '.output' ) ##.join("\n").split(/\n/)
	     code="" 
	    else
	      txt=@@out=[]
	    end 
	    if optout and optout.keys.include? "short"
	      short=optout["short"].split(",")
	      short[0]=short[0].to_i
	      short[2]=short[2].to_i
	      (0...short[0]).each{|i| output << txt[i] << "\n"}
	      output << short[1] << "\n"
	      le = txt.length
	      ((le-short[2])...le).each{|i| output << txt[i] << "\n"}
	    else
	      output << txt.join("\n")
	      output += "\n" if @@out.length>0
	    end
	    inputs << input
	    outputs << output.gsub(/^[\n]*/,"")
	    input,output="",""
	  end
	  optout=nil 
	  hide -= 1 if hide>0
	  passe -=1 if passe>0
	end
      }
      return {:in=>inputs,:out=>outputs}
    end


    @@mode=:capture_cqls #or :capture_protected or capture_normal or capture_local
    
    def RServer.mode=(val)
      @@mode= val
    end
    
    def RServer.mode
      @@mode
    end

    @@device="png"
    
    def RServer.device(dev="pdf")
      @@device=dev
    end
    
    #def RServer.input_semi_colon(block)
    #  block.map{|e| e.chomp!;((e.include? ";") ? (ee=e.split(";");["##!eval",e,"##hide:#{ee.length}"]+ee) : e )}.compact.join("\n")
    #end
    
    def RServer.inputsAndOutputs(block,id="",optRDevice="",prompt={:normal=>'',:continue=>''},env="Global")
      envLoc=env
      optRDevice=(@@device=="png" ? "width=10,height=10,units=\"cm\",res=128" : "width=5,height=5,onefile=FALSE") if optRDevice.empty?
      R4rb << "require(dyndoc)" if @@mode==:capture_cqls
      results=[]
      input,output="",""
      optout,optpasse=nil,nil #options for the output
      hide,passe,passeNb=0,0,0
      echo,echoLines=0,[]
      opt = nil
      code=""
      # add R device
      imgdir=($dyn_rsrc ? File.join($dyn_rsrc,"img") : "/tmp/Rserver-img"+rand(1000000).to_s)
      
      imgfile=File.join(imgdir,"tmpImgFile"+id.to_s+"-")
      cptImg=0
      imgCopy=[]

      FileUtils.mkdir_p imgdir unless File.directory? imgdir
      Dir[imgfile+"*"].each{|f| FileUtils.rm_f(f)}
#p Dir[imgfile+"*"]
      R4rb << "#{@@device}(\"#{imgfile}%d.#{@@device}\",#{optRDevice})"
      #block=RServer.input_semi_colon(block)
      # the following  is equivalent to each_line!
      block.each_line{|l|
	      l2=l.chomp
	      #Dyndoc.warn l2
	      inst=l2.delete(" ").split("|")[0]
	      #Dyndoc.warn "inst",inst
	      if inst and inst[0,2]=="##"
	        #if inst
	          inst=inst.split(":")
	          ## number of lines to apply
	          nb = 1 #default
	          nb=inst[1].to_i if inst.length>1
	          ## instr to exec
	          inst=inst[0].downcase
	        #else
	        #  inst="line"
	        #end
	        ## options
	        opt=l2.split("|")
	        if opt.length>1
	          opt2=opt[1..-1]
	          ## of the form key=value like Hash
	          opt2.map!{|elt| elt.split("=")}
	          #p opt2
	          opt={}
	          opt2.each{|elt| opt[elt[0].downcase.delete(" ")]=elt[1..-1].join("=")}
	        else
	          opt=nil
	        end
	        #Dyndoc.warn "opt",opt
	      else
	        inst="line"
	        opt=nil
	      end

        if echo>0
          echo -= 1
          echoLines << l2 
          next
        end
  
        if echo==0 and !echoLines.empty? and !results.empty?
          results[-1][:output] << "\n" unless results[-1][:output].empty?
          results[-1][:output]  << echoLines.join("\n")
          echoLines=[]
	      end

	      case inst
	      when "##echo" ##need to be added
	        echo=nb.to_i
	      when "##!eval"
	        passe= nb.to_i #this is a copy
          	passeNb=nb.to_i #to remember the original nb
	        optpasse=opt
	      when "##out"
	        optout=opt
	      when "##hide"
	        hide = nb.to_i
	      when "##fig"
	        if opt and opt["img"] and !opt["img"].empty?
	          imgName=File.basename(opt["img"].strip,".*")
	          imgName+=".#{@@device}" #unless imgName=~/\.#{@@device}$/
	          imgName=File.join(imgdir,imgName)
	          
	          imgCopy << {:in => imgfile+cptImg.to_s+".#{@@device}",:out=>imgName}
	          opt.delete("img")
	        else
	          imgName=imgfile+cptImg.to_s+".#{@@device}"
	        end
	        puts "DYN ERROR!!! no fig allowed after empty R output!!!" unless results[-1]
	        results[-1][:img]={:name=>imgName}
	        results[-1][:img][:opt]=opt if opt and !opt.empty? 
	        #could not copy file now!!!!
	      when "##add"
	        results[-1][:add]=opt
	      else
	        if hide==0
	          promptMode=(code.length==0 ? :normal : :continue )
	          input << prompt[promptMode] if prompt
	          #puts "before";p l;p envLoc
	          l2,envLoc=RServer.find_envir(l2,envLoc)
	          #Dyndoc.warn "after",l,envLoc
	          input <<  l2 << "\n"
	        end
	        if passe==0 and l2[0,1]!="#"
	          ## redirect R output
	          code << l2 << "\n" ##ajout de "\n" grace à Pierre (le 15/12/05) pour bug: "1:10 #toto" -> pas de sortie car parse erreur n2!!!
	          case @@mode
	          when :capture_cqls
	            ##TODO: instead of only splitting check that there is no 
	            ## or ask the user to use another character instead of ";" printed as is in the input! 
	            codes=code.split(";")
	            evalOk=(R4rb << ".output <<- ''")
	            codes.each{|cod|
	              evalOk &= (R4rb <<  (tmp=".output <<- c(.output,capture.output.cqls({"+RServer.code_envir(cod,envLoc)+"}))"))
	              #Dyndoc.warn "tmp",tmp
	            }
              when :capture_protected
	            ##TODO: instead of only splitting check that there is no 
	            ## or ask the user to use another character instead of ";" printed as is in the input! 
	            codes=code.split(";")
	            evalOk=(R4rb << ".output <<- ''")
	            codes.each{|cod|
	              evalOk &= (R4rb <<  (tmp=".output <<- c(.output,capture.output.protected({"+RServer.code_envir(cod,envLoc)+"}))"))
	              #Dyndoc.warn "tmp",tmp
	            }
	          when :capture_normal
	            codes=code.split(";")
	            evalOk=(R4rb << ".output <<- ''")
	            codes.each{|cod|
	              evalOk &= (R4rb <<  (tmp=".output <<- c(.output,capture.output({"+RServer.code_envir(cod,envLoc)+"}))"))
	            }
	          when :sink #Ne marche pas à cause du sink!!!
	            evalOk=(R4rb << (tmp=%{
	              zz <- textConnection(".output", "w")
	              sink(zz)
	              local({
	                #{code}
	              },.GlobalEnv$.env4dyn$#{envLoc}
	              )
                sink()
                close(zz)
                print(.output)
                }))
                #Dyndoc.warn "tmp",tmp
              when :capture_local
                codes=code.split(";")
                evalOk=(R4rb << ".output <<- ''")
	            codes.each{|cod|
                cod=".output <<- c(.output,capture.output({local({"+cod+"},.GlobalEnv$.env4dyn$#{envLoc})}))"
                #Dyndoc.warn cod
	              evalOk &= (R4rb << cod )
	            }
	          end
	          cptImg += 1 if File.exists? imgfile+(cptImg+1).to_s+".#{@@device}"
	          #p evalOk;p code;R4rb << "print(geterrmessage())";R4rb << "if(exists(\".output\") ) print(.output)"
	          if evalOk
	            txt=(@@out < '.output' ) ##.join("\n").split(/\n/)
	            code="" 
	          else
	            txt=@@out=[]
	          end 
	          if optout and optout.keys.include? "short"
	            short=optout["short"].split(",")
	            short[0]=short[0].to_i
	            short[2]=short[2].to_i
	            (0...short[0]).each{|i| output << txt[i] << "\n"}
	            output << short[1] << "\n"
	            le = txt.length
	            ((le-short[2])...le).each{|i| output << txt[i] << "\n"}
	          else
	            output << txt.join("\n")
	            output += "\n" if @@out.length>0
	          end
	          input=RServer.formatInput(input)
	          output=RServer.formatOutput(output)
	          #if hide==0
	            result={}
	            result[:input]= (hide==0 ? input : "")
	            result[:prompt]= (hide==0 ? promptMode : :none)
	            result[:output]=output.gsub(/^[\n]*/,"")
	            results << result
	          #end
	          input,output="",""
	          
	        end
	        if passe==0 and l2[0,1]=="#"
	          result={}
	          result[:input]=input
	          result[:prompt]=promptMode
	          result[:output]=""
	          results << result
	          input,output="",""
	        end
	        if passe>=1
	          result={}
	          result[:input]=input
	          result[:prompt]= ( passe == passeNb ? :normal : :continue )#promptMode
	          result[:output]= ((optpasse and optpasse["print"]) ? optpasse["print"] : output)
	          results << result
	          input,output="",""
	        end
	        optout=nil 
	        hide -= 1 if hide>0
	        passe -=1 if passe>0
	      end
      }
      R4rb << "dev.off()"
      imgCopy.each{|e|
	      FileUtils.mkdir_p File.dirname(e[:out]) unless File.exist? File.dirname(e[:out])
	      if File.exists? e[:in] 
	        FileUtils.mv(e[:in],e[:out])
	      else
	        Dyndoc.warn "WARNING! #{e[:in]} does not exists for #{e[:out]}"
	        Dyndoc.warn "RServer:imgCopy",imgCopy
          	Dyndoc.warn "imgDir",Dir[imgdir+"/*"]
	      end
      }
      #TODO: remove all the file newly created!
      return results
    end
 
    @@out=[]

    @@start,@@stop="\\{","\\}"

    def RServer.formatOutput(out)
      #out2=out.gsub(/\\n/,'\textbackslash{n}')
      out.gsub("{",'\{').gsub("}",'\}')
    end
    
    def RServer.formatInput(out)
      out2=out.gsub(/\\n/,'\textbackslash{n}')
      unless out2=~/\\\w*\{.*\}/
        out2.gsub("{",'\{').gsub("}",'\}')
      else
        out2
      end
    end
    

    def RServer.filter(str)
      ## modified (28/5/04) (old : /\#R\{.+\}/ => {\#R{ok}} does not work since "ok}" was selected !!
      res=str.gsub(/\\?(?i:\#|\:)[rR]#{@@start}[^#{@@stop}]+#{@@stop}/) {|w|
	      if w[0,1]=="\\"
	        w[1..-1]
	      else
	        code=w[3..-2] #the key
          RServer.output(code,w[1,1]=="r")
	      end
      }
      res
    end

    def RServer.init_envir
    	##Dyndoc.warn "Rserver.init_envir!!!",Rserve.client
      	"if(!exists(\".env4dyn\",envir=.GlobalEnv)) {.GlobalEnv$.env4dyn<-new.env(parent=.GlobalEnv);.GlobalEnv$.env4dyn$Global<-.GlobalEnv}".to_R
    	##Dyndoc.warn "Global?",RServer.exist?("Global")
	end

    def RServer.exist?(env)
#puts "Rserver.exist? .env4dyn"
#"print(ls(.GlobalEnv$.env4dyn))".to_R
      "\"#{env}\" %in% ls(.GlobalEnv$.env4dyn)".to_R
    end

    def RServer.new_envir(env,parent="Global")
#puts "New env #{env} in #{parent}"
      ".GlobalEnv$.env4dyn$#{env}<-new.env(parent=.GlobalEnv$.env4dyn$#{parent})".to_R
    end
    
    def RServer.local_code_envir(code,env="Global")
      "local({"+code+"},.GlobalEnv$.env4dyn$#{env})"
    end

    def RServer.code_envir(code,env="Global")
      "evalq({"+code+"},.GlobalEnv$.env4dyn$#{env})"
    end

    def RServer.eval_envir(code,env="Global")
      #R4rb << "evalq({"+code+"},.GlobalEnv$.env4dyn$#{env})" ##-> replaced by
      R4rb << RServer.code_envir(code,env)
    end

    def RServer.find_envir(code,env)
#p code
#p env
      codeSaved=code.clone
      code2=code.split(/(\s*[\w\.\_]*\s*:)/)
#p code2
      if code2[0] and code2[0].empty?
        env=code2[1][0...-1].strip
        code=code2[2..-1].join("")
      end
      env2=env.clone
      env=CqlsDoc.vars[env+".Renvir"] unless RServer.exist?(env)
      unless RServer.exist?(env)
        puts "Warning! environment #{env2} does not exist!"
        code=codeSaved
        env="Global"
      end
      return [code,env]
    end

    def RServer.output(code,env="Global",pretty=nil)
      	code,env=RServer.find_envir(code,env)
      	code="{"+code+"}"
#Dyndoc.warn "RServer.output",code
#Dyndoc.warn "without",code,(@@out < "evalq("+code+",.env4dyn$"+env+")"),"done"
      	code="prettyNum("+code+")" if pretty
#Dyndoc.warn "with",code,(@@out < "evalq("+code+",.env4dyn$"+env+")"),"done"
		
      	## code="evalq("+code+",envir=.GlobalEnv$.env4dyn$"+env+")" ##-> replaced by
      	code=RServer.code_envir(code,env)
#Dyndoc.warn "RServer.output->",code,(@@out < code)
      	(@@out < code) #.join(', ')
    end

    def RServer.safe_output(code,env="Global",opts={}) #pretty=nil,capture=nil)
#Dyndoc.warn "opts",opts
      	code,env=RServer.find_envir(code,env)
      	invisible=code.split("\n")[-1].strip =~ /^print\s*\(/
      	code="{"+code+"}"
#Dyndoc.warn "RServer.output",code
#Dyndoc.warn "without",code,(@@out < "evalq("+code+",.env4dyn$"+env+")"),"done"
      	code="prettyNum("+code+")" if opts[:pretty]
#Dyndoc.warn "with",code,(@@out < "evalq("+code+",.env4dyn$"+env+")"),"done"
		
      	## code="evalq("+code+",envir=.GlobalEnv$.env4dyn$"+env+")" ##-> replaced by
      	code=RServer.code_envir(code,env)
#Dyndoc.warn "RServer.output->",code,(@@out < code)
#Dyndoc.warn "RServer.safe_output: capture",capture,code
		if opts[:capture] or opts[:blockR]
			## IMPORTANT; this is here to ensure that a double output is avoided at the end if the last instruction is a print 
			code = "invisible("+code+")" if invisible
			code+=";invisible()" if opts[:blockR]
			#Dyndoc.warn "safe_output",code
			res=(@@out < "capture.output.cqls({"+code+"})")
			#Dyndoc.warn "res", res
			res=res.join("\n")
		else
      		res=(@@out < "{.result_try_code<-try({"+code+"},silent=TRUE);if(inherits(.result_try_code,'try-error')) 'try-error' else .result_try_code}") #.join(', ')
 		end
      	res 
    end

    #more useful than echo_tex!!!
    def RServer.rout(code,env="Global") 
      	out="> "+code
      	code="capture.output({"+code+"})"
      	## code="evalq("+code+",.GlobalEnv$.env4dyn$"+env+")" ##-> replaced by
		code=RServer.code_envir(code,env)
		#puts "Rserver.rout";p code
      	return (@@out< code).join("\n")
    end

    def RServer.init_filter
      R4rb << "require(dyndoc)"
      R4rb << "require(rb4R)"
    end

  end

  class JLServer

 	# def JLServer.init(mode=:default) #mode=maybe zmq (to investigate) 
	# 	require 'jl4rb'
	# 	Julia.init
	# end

	def JLServer.eval(code)
		Julia.eval(code)
	end

  end

end
