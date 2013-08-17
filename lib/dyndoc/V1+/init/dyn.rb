# Goal: same purpose than dyn but used without external files.

######################## common tasks for dyn

# each option have to be set in dyn using cmdparse and in some ruby script by calling some function called dyn with first argument a string to be parsed and the rest corresponding to the same options as the script dyn.

# change global variables replaced by one config variable

require "dyndoc/V1+/init/config"
require 'fileutils'
require "dyndoc/common/utils"
require "dyndoc/V1+/base/utils"

#just for a shortcut
V3={:version=>:V3,
  :docs=>{
    "main"=>{:cmd=>[:save,:pdf,:view]},
  }
}

V3ODT={:version=>:V3,
  :docs=>{
    "main"=>{:cmd=>[:save],:format_doc=>:odt},
  }
}

V3TTM={:version=>:V3,
  :docs=>{
    "main"=>{:cmd=>[:save],:format_doc=>:ttm},
  }
}


module CqlsDoc

  OUTPUTS=[:tex,:txtl,:txt,:tm,:ttm]
  FORMATS=["Tex","Txtl","Txt","Tm","Ttm"]

  DYN={}
  

  def CqlsDoc.init_dyn(versions=[:V3])
    versions.each do |v|
      case v
      when :V3
	      DYN[:V3]=CqlsDoc::V3::Dyn.new
      end
    end
  end

  def CqlsDoc.curDyn
    $curDyn
  end


  def CqlsDoc.set_curDyn(version)
    case version.to_s
      when "V3","3"
        $dyn=$curDyn=DYN[:V3]
        $curDyn[:version]=:V3
        DYN[:V3][:dtag]=:dtag
    end
  end

  def CqlsDoc.read_curDyn(name,mode=:all)
    # $cfg_dyn is the options given by command line
    # cfg_dyn is the options given inside the master template
    version,cfg_dyn=nil,nil
    
    if $cfg_dyn[:version]
      version=$cfg_dyn[:version]
      $cfg_dyn.delete(:version)
      #facility for TTM and ODT
      if ["V3TTM","V3ODT"].include? version
	      cfg_dyn=eval(version)
	      version=cfg_dyn[:version]
	      name_tmpl=CqlsDoc.name_tmpl(name,mode)
	      cfg_dyn[:filename_tmpl_orig]=name_tmpl if name_tmpl
      end
    else
      name_tmpl=CqlsDoc.name_tmpl(name,mode)
#puts "read_curDyn:name_tmpl";p name;p name_tmpl
      if name_tmpl
	      $cfg_dyn[:filename_tmpl_orig]=name_tmpl
	      #puts "read_curDyn:name_tmpl(2)";p name;p name_tmpl
	      name_tmpl2=CqlsDoc.directory_tmpl? name_tmpl
	      if name_tmpl2
	        $cfg_dyn[:filename_tmpl]=name_tmpl2 #record the complete name of the master template 
	        input=File.read(name_tmpl2)
	        cfg_dyn=CqlsDoc.cfg_dyn_from(input,name_tmpl2)
	      else
	        cfg_dyn=Object::V3
#puts "cfg_dyn";p cfg_dyn
	      end
	      version=cfg_dyn[:version].to_s if cfg_dyn and cfg_dyn[:version]
	      version.strip! if version
      end
    end
    CqlsDoc.set_curDyn(version) if version
    p $curDyn[:version] if version and $cfg_dyn[:verbose]
    #otherwise it is the default version!
    $curDyn.append_cfg(cfg_dyn) if cfg_dyn
    #read the optional cfg
    $cfg_dyn.delete(:doc_list) if $cfg_dyn[:doc_list].empty?
    $curDyn.append_cfg($cfg_dyn)
    p $curDyn.cfg if $curDyn[:debug]
    if !$curDyn[:filename_tmpl] or $curDyn[:filename_tmpl].empty?
#puts "read_curDyn:dir";p name_tmpl;p $curDyn[:version]
      name_tmpl2=CqlsDoc.directory_tmpl? name_tmpl
#p name_tmpl2
      $curDyn[:filename_tmpl]=name_tmpl2 if name_tmpl2
    end
    if !$curDyn[:filename_tmpl] or $curDyn[:filename_tmpl].empty?
      raise RuntimeError,"No master template found with name #{name}"
    end
  end

   
  def CqlsDoc.cfg_dyn_from(input,tmpl)
    code,cfg_file=nil,nil
    code=File.read(cfg_file) if (cfg_file=(Dyndoc::Utils.cfg_file_exists? tmpl))
    ##puts "code";p code;p cfg_file
    Utils.clean_bom_utf8!(code) if code
    code=input.scan(/%%%(?:cfg|config|all|dyn)\((.*)\)(?:cfg|config|all|dyn)?%%%/m).flatten[0] unless code
    code="V3" unless code
    if code and code.is_a? String
        code="{\n"+code+"\n}" if code=~/\A\s*\:/m #to avoid at the beginning { and at the end }!
        return Object.class_eval(code)
    end
    return nil
  end

  def CqlsDoc.clean_cfg_dyn_from(input)
    input.gsub(/%%%(?:cfg|config|all|dyn)\((.*)\)(?:cfg|config|all|dyn)?%%%\n?/m,"") 
  end

  def CqlsDoc.dyn
    $dyn if $dyn
  end

=begin TO_REMOVE
  def CqlsDoc.dynOLD
    $dynOLD if $dynOLD
  end

  def CqlsDoc.old?
    $dynOLD and $dynOLD[:dtag]==:OLD
  end
=end

  module DynConfig

    def init_cfg(cfg=nil)
      @cfg=@@cfg.dup
      read_cfg(cfg) if cfg
    end

    def read_cfg(cfg)
      cfg.each_key do |k|
        @cfg[k]=cfg[k]
      end
    end

    # append with partial match
    def append_cfg(cfg)
      return unless cfg.respond_to? "[]"
      keys=@cfg.keys.map{|e| e.to_s}.sort
      cfg.each_key do |k|
	      #like R, partial match of the parameter names
	      if k2=keys.find{|e| e=~/^#{k}/}
	        @cfg[k2.to_sym]=cfg[k]
	      end
      end
    end

    def [](key)
      @cfg[key]
    end

    def []=(key,value)
     @cfg[key]=value
     return self
    end

  end

  module DynAction

=begin TO_REMOVE
    def dynOLD?
      @cfg[:dtag]==:OLD
    end
=end

    def name_dtag(name)
      dtag=name.scan(/(?:#{@cfg[:dtags].map{|e| "_#{e}_" }.join("|")})/)[0]
      if dtag
	      @cfg[:dtag]=dtag[1...-1].to_sym
	      name=name.gsub(/(?:#{@cfg[:dtags].map{|e| "_#{e}_" }.join("|")})/,"")
      end
      return name
    end

# name ###################################################
# texname
    def name_tex(name)
      if (tmp=name.scan(/(.*)(?:_tmpl\.tex|\.dyntex|\.dyn)/)[0])
        name=tmp[0]
      end
      name=name_dtag(name)
    end

# txtname (unused)
    def name_txt(name)
      if (tmp=name.scan(/(.*)(?:_tmpl\.(.*)|\.(dyn))/)[0])
        name,ext=tmp[0],tmp[1]
        if ext and @cfg[:output]==:txt and (CqlsDoc::OUTPUTS.include? ext.to_sym)
          @cfg[:output]=ext.to_sym 
          CqlsDoc.mode=(@cfg[:output])
        end
      end
      name
    end

    #only for version before V2
    def output_name
      #if out_tag not specified 
      @cfg[:out_tag]=[:default] if @cfg[:out_tag].empty?
      #fill the associated 
      @cfg[:out_tag].each{|tag|
        append=""
        append=( CqlsDoc.appendVar[tag] ? CqlsDoc.appendVar[tag] : "_"+tag ) unless tag==:default
        # content for each out_tag
        @cfg[:content][tag]=""
        # content of each output filename
        @cfg[:output_name][tag]=@basename+append
      }
    end

# start ##################################################
    def start
      init(@cfg[:output])
      case @cfg[:output]
        when :tex
	        @filename=name_tex(@name)
        when :txt,:txtl,:tm
          @filename=name_txt(@name)
	      else
	        @filename=@name.dup #unused
      end
      @dirname,@basename=File.split(@filename)
      CqlsDoc.cfg_dir[:file]=File.expand_path(@dirname)
      @curdir=Dir.pwd
      # read current path if it exists
      cur_path=File.join(@dirname,".dyn_path")
      CqlsDoc.setRootDoc(@cfg[:rootDoc],File.read(cur_path).chomp,true) if File.exists? cur_path
      CqlsDoc.make_append unless CqlsDoc.appendVar
    end

    def cd_new
      Dir.chdir(@dirname)
    end

    def cd_old
      Dir.chdir(@curdir)
    end

#like txt (see below) but for string!
    def output(input,echo=0)
      @cfg[:cmd]=:txt
      @cfg[:output]=:txt if @cfg[:output]== :tex
      @cfg[:raw_mode],@cfg[:model_tmpl]=false,nil
      init(@cfg[:output])
      @tmpl.echo=echo
      @tmpl.reinit 
      @tmpl.output input
    end

#notify (constraint name have to complete!)
    def notify
      $dyn_rinotify.add_watch(@name, RInotify::MODIFY)


      # sit and watch the file.  Time out after 2 seconds.
      event_thread = Thread.new do
        while (1)
          has_events = $dyn_rinotify.wait_for_events(2)
          if has_events
            # iterate through events
            $dyn_rinotify.each_event {|revent|
              if revent.check_mask(RInotify::MODIFY)
                server
                trap("INT") do
                  print "QUIT\n"
                  $dyn_rinotify.close
                  exit
                end
              end
            }
          end
        end
      end
      event_thread.join
    end

    def server
      start
      cd_new
      case @cfg[:cmd]
        when :tex
          make_tex
          cd_old
        when :pdf
          make_tex
          make_pdflatex
          cd_old
          make_viewpdf
        when :png
          make_tex
          make_dvipng
          cd_old
          make_viewpng
        when :txt
          make_txt
          cd_old
      end
      @tmpl.reinit
      @tmpl.global={}
    end

# file ############################################
# file tex
    def tex(name)
      @cfg[:cmd]=:tex
      @name=name
      start
      cd_new
      make_tex
      make_backup
      cd_old
    end

# file pdf
    def tex_pdf(name)
      @cfg[:cmd]=:pdf
      @name=name
      start
      cd_new
      make_tex
      make_backup
      make_pdflatex
      cd_old
    end

# file pdf+viewer
    def tex_xpdf(name)
      tex_pdf(name)
      make_viewpdf
    end

# file png
    def tex_png(name)
      @cfg[:cmd]=:png
      @name=name
      start
      cd_new
      make_tex
      make_dvipng
      cd_old
      make_viewpng
    end

#file txt
    def txt(name)
      @cfg[:cmd]=:txt
      @cfg[:output]=:txt if @cfg[:output]== :tex
      @cfg[:raw_mode],@cfg[:model_tmpl]=false,nil
      @name=name
      start
      cd_new
      make_txt
      cd_old
    end

# make ###########################################
# make tex
   def make_tex
      output_name
#p @cfg[:out_tag]
      if @cfg[:debug]
        @tmpl.echo=0
        @tmpl.write @basename
        print "\ndyn tex #{@cfg[:output_name].values.join(',')} -> ok\n"
      else
        begin
          @tmpl.echo=0
          @tmpl.write @basename
          print "\ndyn tex #{@cfg[:output_name].values.join(',')} -> ok\n"
        rescue
          ok=false
          print "\ndyn tex #{@cfg[:output_name].values.join(',')} -> no\n"
        end
      end
    end

# make txt
    def make_txt
      output_name
      if @cfg[:debug]
        @tmpl.echo=0
        @tmpl.write @basename
        print "\ndyn txt #{@cfg[:output_name].values.join(',')} -> ok\n"
      else
        begin
          @tmpl.echo=0
          @tmpl.write @basename
          print "\ndyn txt #{@cfg[:output_name].values.join(',')} -> ok\n"
        rescue
          #ok=false
          print "\ndyn txt #{@cfg[:output_name].values.join(',')} -> no\n"
        end
      end
    end

# make backup

    def make_backup
      ok=nil
      ok= :local if File.exists?( (backup_dir=".dyn_backup"))
      ok=:home if !ok and @cfg[:backup] and @cfg[:backup_home] and File.exists?( (backup_dir=@cfg[:backup_home]))
puts "backup=#{(ok ? ok.to_s : 'nil')}\n"
      if ok
        tmp=Time.now
        tmp_day=".#{tmp.year}#{tmp.month}#{tmp.day}"
        tmp_time=""
        tmp_time += "_#{tmp.hour}" if [:hour,:min,:sec].include? @cfg[:backup_format]
      
        tmp_time += ":#{tmp.min}" if [:min,:sec].include? @cfg[:backup_format]
        tmp_time += ":#{tmp.sec}" if [:sec].include? @cfg[:backup_format]
        tmp_file=CqlsDoc.doc_filename(@basename)
        tmp2=File.split(tmp_file)
        tmp_dir=tmp2[0].gsub(Regexp.escape(File::Separator),"_")
        tmp_basename=tmp2[1]
        case ok
          when :local
            backup_file=tmp_basename+tmp_day+tmp_time
          when :home
            backup_file=tmp_basename+tmp_day+tmp_time+tmp_dir
        end
        # make the backup
        puts "copy #{tmp_file} -> #{backup_file}"
        FileUtils.cp(tmp_file,File.join(backup_dir,backup_file))
      end
    end

# make pdflatex
    def make_pdflatex
      if @cfg[:cmd]==:pdf
        @cfg[:out_tag].each{|ot|
          system "pdflatex #{@cfg[:output_name][ot]}.tex"
          print "\npdflatex #{@cfg[:output_name][ot]}.tex -> ok\n"
        }
      end
    end

# make latex and dvipng 
    def make_dvipng
      if @cfg[:cmd]==:png #possibility to change this option like tex2pdf???
        system "latex #{@basename}.tex"
        print "\nlatex #{@basename}.tex -> ok\n"
        system "dvipng --nogssafer #{@basename}.dvi -o #{basename}.png"
        print "\ndvipng --nogssafer #{@basename}.dvi -o #{basename}.png -> ok\n"
      end
    end


# make view pdf
    def make_viewpdf
      if @cfg[:cmd]==:pdf and !(["no","=no"].include? @cfg[:pdfviewer].downcase)
        @cfg[:out_tag].each{|ot|
          if @cfg[:pdfviewer]=="xpdf"
##test xpdf is  already open
            if `ps aux`.scan("xpdf-#{@cfg[:output_name][ot]}").length>0
              system "xpdf -remote xpdf-#{@cfg[:output_name][ot]} -reload"
            else
              system "xpdf -remote xpdf-#{@cfg[:output_name][ot]}  #{@cfg[:output_name][ot]}.pdf&"
            end
            print "\nxpdf #{@cfg[:output_name][ot]}.pdf -> ok\n"
          else
            `#{@cfg[:pdfviewer]} #{@cfg[:output_name][ot]}.pdf&`
          end
        }
      end
    end

# make view png
    def make_viewpng
      if @cfg[:cmd]==:png and !(["no","=no"].include? @cfg[:pngviewer].downcase)
        system "#{@cfg[:pngviewer]} #{@filename}.png&"
      end
    end

    def get_cfg(name)
      @cfg[:cmd]=:cfg
      @name=name
      start
      cd_new
      input=CqlsDoc.input_from_file(@basename)
      puts "Root paths:\n"
      puts "===========\n"
      #p input.scan(/%%%path\((.*)\)/).flatten.map{|e| e.split(",")}.flatten.map{|e| e.strip.downcase}.join(":")
      p CqlsDoc.get_pathenv(@cfg[:rootDoc])
      puts "where user-defined Root paths (in <DYN_HOME>/etc/path/V3):\n"
      p @cfg[:rootDoc]
=begin
      puts "Part tags:\n"
      puts "==========\n"
      @tmpl.init_tags( input )
=end
      cd_old
    end

  end

end
