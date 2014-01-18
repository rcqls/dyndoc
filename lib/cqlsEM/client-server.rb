require 'eventmachine'
require 'socket'
require (RUBY_VERSION <= "1.8.7" ? 'zip/zip' : 'zip')
require 'fileutils'
require 'zlib'

module CqlsLinker

    attr_reader :linker

    def CqlsLinker.linker
        return({})
    end
    
    def init_linker(key)
        @linker=linker
        @linker[key]=self
    end
end


module CqlsClientServer

    TOKEN = "__[[END_TOKEN]]__"

    attr_accessor :cmd

    def init_com(who)
        @who=who
        @windows_platform = (RUBY_PLATFORM =~ /(win|w)32$/ ? true : nil )
        send_cmd :windows_platform, @windows_platform
        @recv_buffer = BufferedTokenizer.new(TOKEN)
    end
    
    def unzip_file (file, destination)
        unzipped_files = []
        begin
        Zip::ZipFile.open(file) { |zip_file|
            zip_file.each { |f|
                f_path=File.join(destination, f.name)
                puts "[#{@who}] unzip #{f_path}"
                FileUtils.mkdir_p(File.dirname(f_path))
                unless File.exist?(f_path)
                    zip_file.extract(f, f_path)
                    unzipped_files<< f_path
                end
            }
        }
        rescue
           unzipped_files = [] 
        end
        unzipped_files
    end
  
    def send(data)
        send_data data+TOKEN
    end
    
    def prepare_cmd(cmd,param)
        "__send_cmd__[["+cmd.to_s+"]]__"+param.to_s
    end

    def send_cmd(cmd,param="")
         ##send "__send_#{cmd.to_s}__\[\[#{param.to_s}\]\]__"    
         send(prepare_cmd(cmd,param))
    end

=begin
    def send_files(msg=nil,info="")
        if @files && @files.length > 0
            file = @files.shift #file[0]=path to sender, file[1]=path to receiver
            EM.next_tick do
                if File.exists? file[0]
                    puts "[#{@who}] sending #{file[0]} -> #{file[1]}"
                    send_data "__send_file[[#{file[1]}]]__"
                
                    EM::Deferrable.future( stream_file_data(File.expand_path(file[0])) ) {
                        send "" #to end the transfert
                        send_files(msg,info) #maybe a next file to sent
                    }
                else
                    puts "[#{@who}] file #{file[0]} unavailable!"
                    send_files(msg,info) #maybe a next file to sent
                end
            end
        else
            puts "[#{@who}] done syncing files"
            if msg
                info="sent: #{msg}" if info.empty?
                puts "[#{@who}] #{info}"
                send msg
            end 
        end
    end
=end
#=begin
    def post_send_files
        ## to redefine!
    end

    def send_files(msg=nil,info="")
        if @files && @files.length > 0
            file = @files.shift #file[0]=path to sender, file[1]=path to receiver
            EM.next_tick do
                if file[0] and File.exists? file[0]
                    puts "[#{@who}] sending FILE #{file[0]} -> #{file[1]}"
                    send_data "__send_file__[[#{file[1]}]]__"
                    ## contents=File.read(File.expand_path(file[0])) => does not work for binary file on Windows!!!!
                    contents=open(File.expand_path(file[0]), "rb") {|io| io.read }
                    ###DEBUG: p contents[0..100]
                    ###DEBUG: puts "[#{@who}] file size #{contents.length}"
                    ##contents = Zlib::Deflate.deflate(contents,Zlib::BEST_SPEED) #if COMPRESS
                    send contents 
                else
                    puts "[#{@who}] file #{file[0]} unavailable!"
                end
                send_files(msg,info) #maybe a next file to sent
            end
        else
            puts "[#{@who}] done syncing files"
            post_send_files
            if msg
                info="sent: #{msg}" if info.empty?
                puts "[#{@who}] #{info} (#{msg})"
                
                send_cmd msg
                
            end 
        end
    end
#=end
    
    def receive_data(data)
        @recv_buffer.extract(data).each do |m2| 
            ##extract does not split properly if TOKEN is between two sent messages! 
            ##this fix the problem! Alternative is maybe to recode BufferTokenizer class!
            m2.split(TOKEN).each{|m| process_file(m) unless process_cmd(m) }
        end
    end
 
=begin   
    def process(data)
        #to fill if necessary
    end
=end
    
    def process_cmd(data)
        if data =~ /^__send_cmd__\[\[(.*)\]\]__/
            ##cmd="do_"+$1+"(\""+$'+"\")"
            cmd,param=$1,$'
            ##puts "cmd";p cmd;puts "param";p param
            param.empty? ? method("do__"+cmd).call : method("do__"+cmd).call(param)
            return true
        else 
            return nil
        end
    end

    def do__windows_platform(data="")
        @connected_windows_platform = (data.empty? ? nil : true)  
    end
    
    def process_file(data)
        if data =~ /^__send_file__\[\[(.*)\]\]__/
            filename,contents=$1,$'
            ###DEBUG: p contents[0..100]
            ##contents=Zlib::Inflate.inflate(contents)
            ###DEBUG: 
            puts "[#{@who}] file (#{filename}) size #{contents.length}"
            mode="w"
            ## binary content? (same  as in ptools)
            tmp=contents.split(//)
            is_binary_content=((tmp.size - tmp.grep(" ".."~").size) / tmp.size.to_f) > 0.30
            mode += "b" if @windows_platform and is_binary_content
            ###DEBUG: puts "mode=#{mode}"
            File.open(filename,mode) do |f|
                f << contents
            end 
            ###DEBUG: 
            puts "[#{@who}] file (#{filename}) received"
            return true      
        else 
            return nil
        end
    end
    
    def receive_keyboard(line)
        send(prepare_cmd(@cmd,line)) #to redefine if needed!
    end
  
end


class CqlsClientKeyboard < EM::Connection

  include EM::Protocols::LineText2
  include CqlsLinker

  def initialize(linker=nil)
    init_linker(:keyboard) if linker
  end

  def receive_line(data)
    if data=="exit"
        EM::stop
    elsif linker
        linker[:client].receive_keyboard(data)
    end
  end
  
end

