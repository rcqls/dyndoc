require 'eventmachine'
require 'yaml'
require 'socket'
require 'cqlsEM/client-server'
require 'zip/zip'
require 'fileutils'



##########################################

class DyndocClient < EventMachine::Connection

    include CqlsClientServer

    def initialize(cfg=nil)
        super 
        init_com("Client")
        # stuff here...
        @cfg=cfg
        if !@cfg
            puts "[Client] sent server to exit"
            send_cmd :server_to_exit
        else
            @cfg[:filename_client][:name]=File.expand_path @cfg[:filename_client][:name]
            @cfg[:filename_client][:basename_ext]=File.basename(@cfg[:filename_client][:name])
            @cfg[:filename_client][:basename]=File.basename(@cfg[:filename_client][:name],".*")
            @cfg[:filename_client][:dirname]=File.dirname(@cfg[:filename_client][:name])
            
            @filename = @cfg[:filename_client][:name]
            @basename = @cfg[:filename_client][:basename_ext]
            
            @cfg[:filename_client][:dirname] = @filename if File.directory? @filename
            @dirname = @cfg[:filename_client][:dirname]

            room_mode,room=@cfg[:dyndoc_room].split("://")
            if room_mode=="dropbox" and File.split(room)[1]=="Home" #only when you are the user
                room_root=File.split(room)[0] #only the first part  of the path defines the user dropbox
                @cfg[:dirname_docs]=File.expand_path(File.join("~/Dropbox/Dyndoc",room_root,"rooms"))
                unless File.directory? @cfg[:dirname_docs]
                    puts "[Client] Error #{@cfg[:dirname_docs]} not a valid Dropbox directory => close connexion"
                    close_connection
                end
            else
                @cfg[:dirname_docs]=@dirname if !@cfg[:dirname_docs] and File.directory? @dirname
            end
            #p @cfg
            ##send "__cfg__"+YAML.dump(@cfg)
            send_cmd(:cfg,YAML.dump(@cfg))
        end
    end

    def do__client_to_exit
        puts "[Client] client to exit!"
        puts "[Client] check existence of filesOUT!"
        current_dir=FileUtils.pwd
        FileUtils.cd @dirname
        FileUtils.rm_rf "filesOUT" if File.directory? "filesOUT"
        outzip="filesOUT.zip"
        if File.exists? outzip
            Zip::ZipFile.open(outzip) { |zip_file|
                zip_file.each { |f|
                    f_path=File.join(f.name)
                    puts "[Client] unzip #{f_path}"
                    FileUtils.mkdir_p(File.dirname(f_path))
                    unless File.exist?(f_path)
                        zip_file.extract(f, f_path)
                    end
                }
            }
            FileUtils.rm outzip
        end
        logfile=@cfg[:filename_client][:basename]+".dyn_log"
        if File.exist? logfile
            if File.read(logfile).empty?
                FileUtils.rm logfile 
            else
                puts "[Client] Server says:\n"+File.read(logfile)
            end
        end
        FileUtils.cd current_dir

        if @files_to_remove and !@files_to_remove.empty?
            @files_to_remove.each {|f|
                puts "[Client] file #{f} removed!"
                FileUtils.rm f
            }
        end

        puts "[Client] closing connection!"
        close_connection_after_writing
        puts "[Client]  connection closed!"
    end

    def do__get_files
      ## files to init #create them even if not really needed for $cfg_dyn[:dyndoc_room]
      @files=[]
      @files_to_zip=[]
      @files_to_remove=[]

      #if room_mode == :file 
      if $cfg_dyn[:dyndoc_room] and $cfg_dyn[:dyndoc_room] !~ /^dyn\:\/\//#remote does not need to be updated!
        puts "[Client] no files to send to the server"
        send_files :dyndoc, "dyndoc to process"
      else
        puts "[Client] sending files to server"
        zipfilename=File.join(File.dirname(@filename),File.basename(@filename,".*")+".zip")
        FileUtils.rm zipfilename if File.exists? zipfilename
        current_dir=FileUtils.pwd
        FileUtils.cd @dirname
        if @dirname == @filename #directory project
          @cfg[:proj_list] += Dir["*"]
          p @cfg[:proj_list]
          unless @cfg[:proj_list].include? @basename
            puts "[Client] #{@basename} not inside #{@dirname}"
            process "__client_to_exit__" 
          end
        else
            @files_to_zip << @basename
            @files_to_zip << @basename+"_cfg" if File.exists? @filename+"_cfg"
        end      
        @files_to_zip += @cfg[:infiles] if @cfg[:infiles] and  !@cfg[:infiles].empty?

        ## -p options to additional files to import
        @cfg[:proj_list].each do |proj|
            if File.exists? proj
                if File.directory? proj
                    @files_to_zip += Dir["#{proj}/**/**"]
                else
                    @files_to_zip << proj
                end
            end
        end
        ##puts "zip!!!";p @files_to_zip;p zipfilename;p FileUtils.pwd;
        Zip::ZipFile.open(zipfilename, Zip::ZipFile::CREATE) do |zipfile|
            @files_to_zip.each do |f|
                puts "[client] sending #{f}"
                zipfile.add(f,f)
            end
        end
        FileUtils.cd current_dir
        
        @files << [zipfilename,File.basename(zipfilename)]
        @files_to_remove << zipfilename
            
        if @files.empty?
           puts "[Client] stops because no files to send"
           close_connection
        else
            send_files :dyndoc, "dyndoc to process"
        end
      end
    end
 
    def unbind
        puts '[Client] connection totally closed'
        EM::stop_event_loop
    end
end
