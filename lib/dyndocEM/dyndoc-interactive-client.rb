require 'eventmachine'
require 'yaml'
require 'socket'
require 'cqlsEM/client-server'
require (RUBY_VERSION <= "1.8.7" ? 'zip/zip' : 'zip')
require 'fileutils'



##########################################

class DyndocInteractiveClient < EventMachine::Connection

    include CqlsClientServer

    def initialize(cfg=nil,content="")
        super 
        init_com("Client")
        # # stuff here...
        @cfg,@content=cfg,content
        puts "content";p @content

        # if !@cfg
        #     puts "[Client] sent server to exit"
        #     send_cmd :server_to_exit
        # else
        #     @cfg[:filename_client][:name]=File.expand_path @cfg[:filename_client][:name]
        #     @cfg[:filename_client][:basename_ext]=File.basename(@cfg[:filename_client][:name])
        #     @cfg[:filename_client][:basename]=File.basename(@cfg[:filename_client][:name],".*")
        #     @cfg[:filename_client][:dirname]=File.dirname(@cfg[:filename_client][:name])
            
        #     @filename = @cfg[:filename_client][:name]
        #     @basename = @cfg[:filename_client][:basename_ext]
            
        #     @cfg[:filename_client][:dirname] = @filename if File.directory? @filename
        #     @dirname = @cfg[:filename_client][:dirname]

        #     room_mode,room=@cfg[:dyndoc_room].split("://")
        #     if room_mode=="dropbox" and File.split(room)[1]=="Home" #only when you are the user
        #         room_root=File.split(room)[0] #only the first part  of the path defines the user dropbox
        #         @cfg[:dirname_docs]=File.expand_path(File.join("~/Dropbox/Dyndoc",room_root,"rooms"))
        #         unless File.directory? @cfg[:dirname_docs]
        #             puts "[Client] Error #{@cfg[:dirname_docs]} not a valid Dropbox directory => close connexion"
        #             close_connection
        #         end
        #     else
        #         @cfg[:dirname_docs]=@dirname if !@cfg[:dirname_docs] and File.directory? @dirname
        #     end
        #     #p @cfg
        #     ##send "__cfg__"+YAML.dump(@cfg)
        do__client_to_exit if @content.empty?
        send_cmd(:cfg,YAML.dump(@cfg))
    end

    def do__client_to_exit
        puts "[Client] client to exit!"
        puts "[Client] closing connection!"
        close_connection_after_writing
        puts "[Client]  connection closed!"
    end

    def do__set_content
        send_cmd(:dyndoc,@content)
    end

    def do__get_content(server_content)
       puts server_content+"\n"
       do__client_to_exit
    end
 
    def unbind
        puts '[Client] connection totally closed'
        EM::stop_event_loop
    end
end