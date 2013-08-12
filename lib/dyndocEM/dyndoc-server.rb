require 'yaml'
require 'cqlsEM/client-server'
require 'ptools'

class DyndocServer < EventMachine::Connection

    include CqlsClientServer

    ##@@clients_list ||= {}
    @@busy=nil

    WorkDir=(RUBY_PLATFORM =~ /(win|w)32$/ ? File.join(ENV["HOME"],"dyndoc-server")  : "/export/dyndoc-server")
    RunDir=File.join(WorkDir,"run") #for the daemons!
    RoomsDir=File.join(WorkDir,"rooms") #for the projects
    GuestRoom="guestOnly"
    FileUtils.mkdir RunDir unless File.exists? RunDir
    FileUtils.mkdir RoomsDir unless File.exists? RoomsDir

    def initialize
        puts "#{self.object_id.to_s} initialized!"
        super
        init_com("Server")
        @room,@room_dir=nil,nil
    end

    def post_init
        puts "#{self.object_id.to_s} connected!"
        #nothing to do for now bu maybe soon!
        ##@identifier = self.object_id
        ##@@clients_list.merge!({@identifier => self})
    end

    def init_server
        ## working_dir saved in dyndocEM under room_dir!
        p $cfg_dyn[:dyndoc_room]
        $cfg_dyn[:dyndoc_mode]=:remote_server if $cfg_dyn[:hostname] != $dyndoc_server_hostname or ($cfg_dyn[:dyndoc_room]=~/^dropbox\:\/\//)
        ##puts "local server!!!";p $cfg_dyn[:hostname];p $dyndoc_server_hostname
        if $cfg_dyn[:dyndoc_mode]==:remote_server
            $cfg_dyn[:working_dir] = working_dir_for_remote_server
        elsif $cfg_dyn[:dyndoc_mode]==:local_server
            @room_dir,@room_mode=$cfg_dyn[:working_dir],:file 
        end
        ## puts "room dir";p @room_dir;puts "room_mode";p @room_mode

        ## before chdir, you need to ensure that room_dir exists!
        unless [:ssh,:file].include? @room_mode
            puts "[Server] dyndoc room created!"
            FileUtils.mkdir_p @room_dir
        else
            unless File.directory? @room_dir
                puts "[Server] ssh project not already open!"
                send_cmd :client_to_exit
                return
            end
        end

        ## go to working directory
        @current_dir=FileUtils.pwd
        puts "[Server] change to working directory!"
        FileUtils.cd(@room_dir)
        return if [:ssh,:file,:dropbox].include? @room_mode
        ## clean the working directory
        puts "[Server] cleaning dyndoc server!"
        Dir["#{@room_dir}/*"].each{|f|
            FileUtils.rm_rf(f)
            FileUtils.mkdir_p("filesOUT")
            puts "[Server] #{File.basename(f)} removed!"
        }
    end

    def working_dir_for_remote_server #only for remote server
        room_path=nil
        if $cfg_dyn[:dyndoc_room] and $cfg_dyn[:dyndoc_room] !~ /^dyn\:\/\//
            @room_mode,@room=$cfg_dyn[:dyndoc_room].split("://")
            @room_mode=@room_mode.to_sym
            pre=case @room_mode
            when :ssh
                "protected"
            when :google
                "google"
            when :dropbox
                "dropbox"
            end
            room_path=File.join(pre,@room)
        else
            @room,room_path,@room_mode=GuestRoom,GuestRoom,:guest
        end
        
        @room_dir=File.join(RoomsDir,room_path)
        return @room_dir
    end

    def guest_room?
        @room_mode==:guest
    end

    def do__cfg(cfg)
        $cfg_dyn=YAML.load(cfg)

=begin
        p $cfg_dyn
        p @@busy
        if @@busy
            puts "[Server] #{$cfg_dyn[:client_cmd_opts][:port]} busy!"
            send_cmd :client_to_exit
            return
        end
        ## server is now busy (mostly because of concurrency of dyndoc activities not available)!
        @@busy=self
=end
        #p $cfg_dyn #to hide!
        timer = EventMachine::PeriodicTimer.new(0.1) do
            if @@busy and @@busy!=self
                puts "[Server] #{@@busy.object_id.to_s} busy and #{self.object_id.to_s} waiting!"
            else
                @@busy=self
                puts "[Server] #{self.object_id.to_s} in use!"
                init_server
                #puts "room (mode,name,dir):"; @room_mode;p @room;p @room_dir
                if @room_mode==:file
                    timer.cancel
                    puts "[Server] No need to ask for files from client"
                    ## directly do dyndoc stuff!
                    do__dyndoc
                else
                    send_cmd :get_files #, @room_mode
                    puts "[Server] asks for files from client"
                    timer.cancel
                end
            end
        end 
    end

    def do__server_to_exit
        EM::stop
        puts "[Server] exit sent by client!"
    end

    def do__dyndoc
        name=$cfg_dyn[:filename_client][:basename_ext]

        if guest_room?
            puts "[Server] unzip first"
            unzipped_files=unzip_file(File.join(@room_dir,File.basename(name,".*")+".zip"),@room_dir)
            if unzipped_files.empty?
                puts "[Server] unzip aborted"
                send_cmd :client_to_exit
                return
            end
            ## clean files if coming from windows
            unzipped_files.each{|f|
                content_tmp=File.read(f)
                unless File.binary?(f)
                    File.open(f,"w") do |f|
                        f << content_tmp.gsub("\r\n","\n")
                    end
                end
            }  
        elsif @room_mode == :google

=begin
            tmp=`google docs list`.strip.split("\n").map{|l| l.split(",")}
            @google_docs_list={};tmp.each{|doc,url| google_docs_list[doc]=url}
=end
            ## TODO: to unblock using EM.system!
            system("google docs get --folder #{@room} #{@room_dir}")
            ## fix text extension: *.*.txt => *.* (useful for at least *.dyn and *.dyn_cfg files)
            Dir["#{@room_dir}/**.*"].each {|f| FileUtils.mv f,$1 if f=~ /(.*\.[^\.]*)\.txt$/}

            if Dir[@room_dir+"/*"].empty?
                puts "[Server] #{@room} is not  a valid (shareable) google collection!"
                send_cmd :client_to_exit
                return
            end
            
        end
       
        puts "[Server] dyndoc process"
        ##send_data ">>> you sent: #{name}"
        puts "=> [Server] File to deal with: "+name+"\n"
        ## check if it exists!
        ##p @room_dir
        unless File.exists? File.join(@room_dir,name)
            puts "[Server] #{name} does not  exist! Dyndoc process aborted!"
            server_not_busy
            send_cmd :client_to_exit
            return
        end

        ## authentification for dropbox
        if @room_mode==:dropbox
            puts "[Server] Dropbox authentification required!" 

            secret,secret_file=nil,File.join(ENV["HOME"],"Dropbox","Dyndoc",File.split(@room)[0],".secret")
 
            # 10 tries to check if secret_file is correct
            n = 0
            begin
                secret=File.read(secret_file) if File.exists? secret_file
                puts "[Server] try #{n+1} at #{Time.now}" 
                sleep 0.5
            end until ((n+=1) > 20) or $cfg_dyn[:dyndoc_secret]==secret
            
            unless $cfg_dyn[:dyndoc_secret]==secret
                puts "[Server] Dropbox authentification failed! Dyndoc process aborted!"
                server_not_busy
                send_cmd :client_to_exit
                return 
            else
                puts "[Server] Dropbox authentification succeed!"
            end
        end

        ## dyndoc process start!
        CqlsDoc.read_curDyn(name) #if nothing specified, :V3 is chosen here!
        unless [:V1,:V2,:V2dtag].include? $curDyn[:version]
            $curDyn.init
            $curDyn.tmpl_doc.make_all
            @files=[]
            ### zipfile=Zip::ZipFile.open(File.join(@room_dir,"zipfile.zip"), Zip::ZipFile::CREATE)
            $curDyn.tmpl_doc.docs.each{|k,v|
                v.cfg[:created_docs].each{|d|
                    @files << [File.join(@room_dir,d),File.join($cfg_dyn[:dirname_docs],d)]
                    ### zipfile.add(d,File.join(@room_dir,d))
                }
            }
            ### @files << [ File.join(@room_dir,"zipfile.zip"), File.join($cfg_dyn[:dirname_docs],"zipfile.zip")]
            ### zipfile.close
            $cfg_dyn[:outfiles].each{|d|
                @files << [File.join(@room_dir,d),File.join($cfg_dyn[:dirname_docs],d)]
            } if $cfg_dyn[:outfiles]

            outfiles=Dir[File.join("filesOUT","**","*")]
            unless outfiles.empty?
                require 'zip/zip'
                require 'fileutils'
                zipfilename=File.join(@room_dir,"filesOUT.zip")
                FileUtils.rm zipfilename if File.exists? zipfilename
                Zip::ZipFile.open(zipfilename, Zip::ZipFile::CREATE) do |zipfile|
                    outfiles.each{|f|
                        zipfile.add(f,f)
                    }
                end
                @files << [zipfilename,File.join($cfg_dyn[:dirname_docs],"filesOUT.zip")]
            end
            
            ## clean temporary files!
            if [:dropbox].include? @room_mode
                base_to_clean=File.basename(name,".*")
                [".log",".aux"].map{|ext|
                    to_clean=File.join(@room_dir,base_to_clean+ext)
                    FileUtils.rm to_clean if File.exists? to_clean
                }
            end
            ## 
            if @room_mode==:file
                server_not_busy
                send_cmd :client_to_exit
            else 
                send_files :client_to_exit, "client needs to exit"
            end
        end

    end

    def server_not_busy
        if @@busy and @@busy==self
            ## NO more dyndoc activities! the server is free! Another can connect!
            @@busy=nil
            puts "[Server] #{self.object_id.to_s} free!"
        end
    end



    def post_send_files
        ## After files sent, one could do next task! 
        server_not_busy
    end
 
    def unbind
        #p @current_dir
        if @current_dir
            puts "[Server] change to current directory!"
            FileUtils.cd(@current_dir)
        end 
        puts "[Server] exit dyndoc server!"
    end

end

class DyndocServerKeyboard < EM::Connection
  include EM::Protocols::LineText2

  def receive_line(data)
    EM::stop if data=="exit"
  end
end
