require 'yaml'
require 'cqlsEM/client-server'
require 'ptools'

class DyndocInteractiveServer < EventMachine::Connection

    include CqlsClientServer

    ##@@clients_list ||= {}
    @@busy=nil

    ##WorkDir=(RUBY_PLATFORM =~ /(win|w)32$/ ? File.join(ENV["HOME"],"dyndoc-server")  : "/export/dyndoc-server")
    WorkDir=File.join(ENV["HOME"],"dyndoc","server")
    RunDir=File.join(WorkDir,"run") #for the daemons!
    RoomsDir=File.join(WorkDir,"rooms") #for the projects
    GuestRoom="guestOnly"
    FileUtils.mkdir RunDir unless File.exists? RunDir
    FileUtils.mkdir RoomsDir unless File.exists? RoomsDir

    def initialize
        puts "#{self.object_id.to_s} initialized!"
        super
        init_com("Server")
        $cfg_dyn={
          :format_output=>"txt",
          :client_cmd=> :cfg,
          :pre_tmpl=>[],:post_tmpl=>[],:out_tag=>[],:part_tag=>[],
          :doc_list=>[],:tag_tmpl=>[],:keys_tmpl=>[],:user_input=>[],:cmd_pandoc_options => [],
          :nbChar_error=> 300,:proj_list=>[],:working_dir=>"",:dyndoc_mode=>:local_interactive_server,
          :dyndoc_session=>:interactive
        }
        @room,@room_dir=nil,nil
    end

    def post_init
        puts "#{self.object_id.to_s} connected!"
        #nothing to do for now bu maybe soon!
        ##@identifier = self.object_id
        ##@@clients_list.merge!({@identifier => self})
    end

    def do__cfg(cfg)
        $cfg_dyn.merge(YAML.load(cfg))
        send_cmd(:set_content)
    end

    def do__dyndoc(content)

        #p $dyndoc_interactive_server #to hide!
        timer = EventMachine::PeriodicTimer.new(0.1) do
            if @@busy and @@busy!=self
                puts "[Server] #{@@busy.object_id.to_s} busy and #{self.object_id.to_s} waiting!"
            else
                @@busy=self
                puts "[Server] #{self.object_id.to_s} in use!"
                #puts "room (mode,name,dir):"; @room_mode;p @room;p @room_dir   
                result=process_dyndoc(content)
                result="__EMPTY_RESULT__" if result.empty?
                timer.cancel
                send_cmd(:get_content,result)
                server_not_busy
            end
        end 
    end

    def do__server_to_exit
        EM::stop
        puts "[Server] exit sent by client!"
    end

    def process_dyndoc(content)
        # initialization once
        unless $cfg_dyn[:interactive_session_started]
            $cfg_dyn[:interactive_session_started]=true
            $curDyn.init(false)
            $curDyn.tmpl_doc.init_doc
            if $cfg_dyn[:interactive_session_libs]
              $curDyn.tmpl_doc.require_dyndoc_libs($cfg_dyn[:interactive_session_libs])
            end 
            "options(bitmapType='cairo')".to_R
            $curDyn.tmpl.format_output=$cfg_dyn[:interactive_session_format_output]
            $curDyn.tmpl.dyndoc_mode=$cfg_dyn[:interactive_session_dyndoc_mode]
        end
        puts "[Server] process dyndoc content"
        $curDyn.tmpl_doc.make_content(content)
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
