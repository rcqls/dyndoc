module CqlsVBox

	class User

		@@users={}

		def User.ls
			@@users.keys
		end

		attr_reader :name, :passwd

		def initialize(name="cqls",passwd="dyndoc")
			@name,@passwd=name,passwd
			@@users[@name]=@passwd
		end

	end

	class VM

		attr_accessor :user, :root

		def initialize(vm="Awesome")
			@vm=vm
			@root="awesome"
			# @user to provide later!
		end


		def start
			print "Starting #{@vm}: "
			`VBoxManage startvm #{@vm} --type headless`
			print "." while !is_ready?
			puts "-> done!"
		end

		def init_forwarding #only ONCE and before starting vm!!!!
			system("VBoxManage modifyvm #{@vm} --natpf1 \"cqlsweb,tcp,,3001,,3001\"")
			system("VBoxManage modifyvm #{@vm} --natpf1 \"guestssh,tcp,,2222,,22\"")
			system("VBoxManage modifyvm #{@vm} --natpf1 \"dyndoc,tcp,,6666,,6666\"")
		end 

		# no result return
		def exec(cmd,args="")
			return unless @user
			#result return
			#`VBoxManage guestcontrol  exec #{vm} "#{cmd}" --arguments "#{args}" --username #{@user.name} --password #{@user.passwd} --wait-for stdout`
			# no result return
			system("VBoxManage guestcontrol #{@vm} exec \"#{cmd}\" --username #{@user.name} --password #{@user.passwd} --wait-stdout -- \"#{args}\" ")
		end

		def exec!(cmd,args="")
			return unless @user
			`VBoxManage guestcontrol #{@vm} exec "#{cmd}" --username #{@user.name} --password #{@user.passwd} --environment HOME=/home/#{@user.name} --wait-stdout -- #{args}  2>&1`
		end

		def exec_and_wait_exit(cmd,args="")
			`VBoxManage guestcontrol #{@vm} exec "#{cmd}" --username #{@user.name} --password #{@user.passwd} --environment HOME=/home/#{@user.name} --wait-exit -- #{args}`
		end

		def exec_as_root(cmd,args="")
			system("VBoxManage guestcontrol #{@vm} exec \"#{cmd}\" --username root --password #{@root} --wait-stdout -- #{args}")
		end

		def exec_and_wait_exit_as_root(cmd,args="")
			`VBoxManage guestcontrol #{@vm} exec "#{cmd}" --username root --password #{@root} --wait-exit -- #{args}`
		end

		def is_ready?
			exec!("/bin/echo","Ready") =~ /Ready/
		end

		def control(mode=:poweroff) #:pause or :resume or :reset
			`VBoxManage controlvm #{@vm} #{mode}`
		end

		def pause
			control :pause
		end

		def resume
			control :resume
		end

		def poweroff
			control :poweroff
		end


		def reset
			control :reset
		end

		def stop(cutoff=1000)
			print "Power off #{@vm}: "
			exec_and_wait_exit_as_root("/sbin/halt")
			cpt=0
			print "." while `VBoxManage list runningvms`=~ /#{@vm}/ and ((cpt+=1) < cutoff)
			poweroff if cpt==cutoff
			puts "-> done!"
		end

		def status
			`VBoxManage showvminfo #{@vm}`.split("\n").select{|l| l =~ /^\s*State\:/}.join("\n")
		end

=begin 

		DYNDOC="/usr/local/bin/dyndoc-ruby"
		DYNDOC_USERS="/home/cqls/VirtualBoxShared/dyndoc-users"

		def dyndoc(doc,opt="-cspdf",room="/") #room could be "/test"
			return unless @user
			exec(DYNDOC," all #{opt} #{DYNDOC_USERS}/#{@user.name}#{room}/#{doc}")
		end

		RUBY="/usr/bin/ruby"
		def ruby(code)
			return unless @user
			code=" -rubygems -e \"#{code}\""
			puts code
			exec!(RUBY,code)
		end
=end

	end

end

Aws=CqlsVBox::VM.new
Aws.user=CqlsVBox::User.new