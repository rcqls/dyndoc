require 'fileutils'
require 'dyndoc/V1+/plugins/odt/odt'

module CqlsDoc

# first declaration of the config directory
  @@cfg_home_root=(ENV["DYN_HOME"] ? ENV["DYN_HOME"] : File.join(ENV['HOME'],'dyndoc'))
  if File.exists?(tmp=File.join(ENV['HOME'],'.dyndoc'))
    @@cfg_home_root=File.expand_path(File.read(tmp).strip)
  end
  @@cfg_dir={
    :sys => File.join(@@cfg_home_root,"etc"), 
    :home => File.join(ENV['HOME'],'dyndoc','etc'),
    :tmpl_path=>{:tex=>"Tex",:odt=>"Odt",:ttm=>"Ttm"},:model_default=>"Model",
    # if $DYN_HOME exists it is the home root
    :home_root=> @@cfg_home_root
  }


  def CqlsDoc.cfg_dir
    @@cfg_dir
  end

  def CqlsDoc.init_dyndoc_library_path
    dyndoc_library_path=File.join(@@cfg_dir[:home],"dyndoc_library_path")
    if File.exists? dyndoc_library_path
      path=File.read(dyndoc_library_path).strip
      if !ENV["DYNDOC_LIBRARY_PATH"] or ENV["DYNDOC_LIBRARY_PATH"].empty?
        ENV["DYNDOC_LIBRARY_PATH"]=path 
      else
        ENV["DYNDOC_LIBRARY_PATH"]+= ":" + path
      end
    end
  end

# rootDoc
  def CqlsDoc.setRootDoc(rootDoc,root,before=true)  
    if rootDoc
      if before
        rootDoc2 = "#{root}:"+rootDoc
     else
        rootDoc2 = rootDoc+":#{root}"
      end
    else
      rootDoc2=root 
    end
    #insure unique path and adress of rootDoc is unchanged!
    rootDoc.replace(rootDoc2.split(":").uniq.join(":")) if rootDoc2
  end
 
  def CqlsDoc.sysRootDoc(root="")
    File.join(__FILE__.split(File::Separator)[0...-2],root)
  end

  def CqlsDoc.mode
    @@mode
  end

  def CqlsDoc.mode=(mode)
    @@mode=mode
  end

  def CqlsDoc.docExt(mode=@@mode)
    @@docExt[mode]
  end

  def CqlsDoc.tmplExt
    @@tmplExt
  end


  ## default mode and extension
  @@mode=:txt
  @@tmplExt={:txt => [".dyn_txt","_tmpl.txt",".dyn"], :rb =>[".dyn_rb","_tmpl.rb",".dyn"], :c=>[".dyn_c","_tmpl.c",".dyn"], :html => [".dyn_html","_tmpl.html","_tmpl.rhtml",".dyn"],:txtl=>[".dyn_txtl","_tmpl.txtl","_tmpl.rhtml",".dyn"],
  :tm=>[".dyn_tm","_tmpl.tm",".dyn"],
  :tex=>[".dyn_tex","_tmpl.tex",".dyn",".rtex"],
  :odt=>[".dyn_odt_content","_tmpl_content.xml",".dyn_odt_styles","_tmpl_styles.xml",".dyn_odt","_tmpl.odt",".dyn"], #_tmpl.odt is an odt file with content body to extract!
  :ttm=>[".dyn_ttm","_tmpl.ttm",".dyn"],
  :all=>[".dyn"]
  }

  @@docExt={:txt => ".txt",:rb => ".rb",:c=>".c",:html=>".html",:txtl=>".rhtml",:tm=>".tm",:tex=>".tex",:odt=>".odt",:ttm=>"_ttm.xml"}

  @@dynExt=[".dyn"]

  EXTS={:txt => ".txt",:rb => ".rb",:c=>".c",:html=>".html",:txtl=>".rhtml",:tm=>".tm",:tex=>".tex",:odt_content=>"_content.xml",:odt_styles=>"_styles.xml",:dyn=>".dynout",:ttm=>"_ttm.xml"}


  def CqlsDoc.guess_mode(filename)
    @@tmplExt.keys.map{|k| k.to_s}.sort.each do |ext|
      return ext.to_sym if filename =~ /(#{@@tmplExt[ext.to_sym].join("|")})$/
    end
    return nil
  end

  def CqlsDoc.init_rootDoc(path_filename='V3')
    ## local config if exists
    path=File.join( @@cfg_dir[:sys],'path',path_filename)
    rootDoc = File.expand_path(File.read(path).chomp)  if File.exists? path
    rootDoc = "" unless rootDoc
    ## global config if exists
    path=File.join(@@cfg_dir[:home],'path',path_filename)
    rootDoc += (rootDoc.empty? ? "" : ":") + File.read(path).chomp if File.exists? path
    rootDoc = nil if rootDoc.empty?
    rootDoc
  end

# append or alias tricks ##########################
  @@append=nil

  def CqlsDoc.appendVar
    @@append
  end

  def CqlsDoc.make_append
    ## global aliases
    @@append={}
    tmp=[]
    sys_append=File.join( @@cfg_dir[:sys],"alias")
    tmp += File.readlines(sys_append) if File.exists? sys_append 
    home_append=File.join(@@cfg_dir[:home],'alias')
    tmp += File.readlines(home_append)  if File.exists? home_append
    file_append=File.join(@@cfg_dir[:file],'.dyn_alias')
    tmp += File.readlines(file_append)  if File.exists? file_append
    tmp.map{|l| 
      if l.include? ">"
        l2=l.strip
        unless l2.empty?
          l2=l2.split(/[=>,]/).map{|e| e.strip} 
          @@append[l2[0]]=l2[-1]
        end
      end
    }
  end

  ## more useable than this !!!   
  def CqlsDoc.absolute_path(filename,pathenv)
#puts "ici";p filename
    return filename if File.exists? filename
    paths=pathenv##.split(":")
#puts "absolute_path:filname";p filename
    name=nil
    paths.each{|e| 
      f=File.expand_path(File.join([e,filename]))
#p f
      if (File.exists? f)
      	name=f
      	break
      end
    }
#puts "->";p name
    name
  end

  def CqlsDoc.directory_tmpl?(name,exts=@@tmplExt[@@mode],version="V3")
    version="V3" unless version
    version=$curDyn[:version].to_s if $curDyn
    if name and File.directory? name
#puts "directory_tmpl?:name";p name;p exts
#p File.join(name,"index")
      resname=CqlsDoc.doc_filename(File.join(name,"index"),exts,false)
      resname=CqlsDoc.doc_filename(File.join(name,File.basename(name,".*")),exts,false) unless resname
#p name
#p File.join(@@cfg_dir[:home_root],["root",$curDyn[:version].to_s,"Default","index"])

##IMPORTANT: this file could not depend on the format_doc because it is related to the template and not the document!!!
      resname=CqlsDoc.doc_filename(File.join(@@cfg_dir[:home_root],["root",version,"Default","index"]),exts,false) unless resname
      name=resname
    end
#puts "directory_tmpl?:return resname";p resname;p name
    return name
  end

  PATH_SEP=";"

  def CqlsDoc.init_pathenv
      if !$cfg_dyn or $cfg_dyn[:dyndoc_mode]==:normal #normal mode
         pathenv="."
      else #client server mode
        #puts "working directory";p $cfg_dyn[:working_dir]
        pathenv = $cfg_dyn[:working_dir] + PATH_SEP + "."
      end
      return pathenv
  end


  def CqlsDoc.ordered_pathenv(pathenv)
    path_ary=[]
    pathenv.split(PATH_SEP).each{|e| 
      if e=~/(?:\((\-?\d*)\))(.*)/ 
        path_ary.insert($1.to_i-1,$2.strip)
      else 
        path_ary << e.strip
      end
    }
    #puts "path_ary";p path_ary
    path_ary.compact.uniq #.join(":")
  end

  $dyn_gem_root=File.dirname(__FILE__).split("/")[0...-4].join("/") unless $dyn_gem_root

  ## dynamically get pathenv!!!!
  def CqlsDoc.get_pathenv(rootDoc=nil,with_currentRoot=true)
    pathenv =  CqlsDoc.init_pathenv
    pathenv += PATH_SEP + File.join($dyn_gem_root,"dyndoc") + PATH_SEP + File.join($dyn_gem_root,"dyndoc","Std") if File.exists? File.join($dyn_gem_root,"dyndoc")
    pathenv += PATH_SEP + File.join(@@cfg_dir[:home_root],"library") if File.exists? File.join(@@cfg_dir[:home_root],"library")
    pathenv += PATH_SEP + ENV["DYNDOC_LIBRARY_PATH"] if ENV["DYNDOC_LIBRARY_PATH"] and !ENV["DYNDOC_LIBRARY_PATH"].empty?
    pathenv += PATH_SEP + $dyndoc_currentRoot if with_currentRoot and $dyndoc_currentRoot and !$dyndoc_currentRoot.empty?
    pathenv += PATH_SEP + rootDoc  if rootDoc and !rootDoc.empty?
    pathenv += PATH_SEP + $cfg_dyn[:rootDoc]  if $cfg_dyn and $cfg_dyn[:rootDoc] and !$cfg_dyn[:rootDoc].empty?
    pathenv += PATH_SEP + ENV["TEXINPUTS"].split(RUBY_PLATFORM =~ /mingw/ ? ";" : ":" ).join(";") if ENV["TEXINPUTS"] and @@mode==:tex
    
    #puts "pathenv";p pathenv
    return CqlsDoc.ordered_pathenv(pathenv)
  end
  
  # if exts is a Symbol then it is the new @@mode!
  def CqlsDoc.doc_filename(filename,exts=@@tmplExt[@@mode],warn=true,pathenv=".",rootDoc=nil)
    rootDoc=$curDyn[:rootDoc] if !rootDoc and $curDyn and $curDyn[:rootDoc]
    filename=filename.strip
    if exts.is_a? Symbol
      @@mode=exts 
      exts=@@tmplExt[@@mode]
    end
     
    pathenv = CqlsDoc.get_pathenv(rootDoc)
    exts = exts+@@tmplExt.values.flatten  #if @cfg[:output]
    exts << "" #with extension
#puts "before finding paths";p filename;p @@mode;p exts
    exts.uniq!
    names=exts.map{|ext| CqlsDoc.absolute_path(filename+ext,pathenv)}.compact
    name=(names.length>0 ? names[0] : nil)
    if warn
      print "WARNING: #{filename} not reachable in #{pathenv.join(":")} with extension #{exts.join(',')}\n" unless name
      #puts "tmpl:";p name
    end
    return name
  end


  def CqlsDoc.input_from_file(filename)
    return CqlsDoc.read_content_file(CqlsDoc.doc_filename(filename))
  end

  # the filename path has to be complete
  def CqlsDoc.read_content_file(filename,aux={})
#p filename
    case File.extname(filename)
    when ".odt"
      odt=CqlsDoc::Odt.new(filename)
      aux[:doc].inputs={} unless aux[:doc].inputs 
      aux[:doc].inputs[filename]= odt unless aux[:doc].inputs[filename]
      odt.body_from_content
    else
      File.read(filename)
    end
  end

  #find the name of the template when mode is given
  def CqlsDoc.name_tmpl(name,mode=:all)
    #clean dtag
    dtags=[:dtag] #update if necessary
    dtag=name.scan(/(?:#{dtags.map{|e| "_#{e}_" }.join("|")})/)[0]
    if dtag
      name=name.gsub(/(?:#{dtags.map{|e| "_#{e}_" }.join("|")})/,"")
    end
#puts "name";p name
    #file exists?
    if File.exists? name
      return name
    elsif name.scan(/([^\.]*)(#{@@tmplExt.map{|e| e[1]}.flatten.uniq.map{|e| Regexp.escape(e)}.join("|")})+$/)[0]
      pathenv=CqlsDoc.get_pathenv($curDyn[:rootDoc],false) #RMK: do not know if false really matters here (introduced just in case in get_pathenv!!!) 
#puts "pathenv";p pathenv; p CqlsDoc.absolute_path(name,pathenv)
      return CqlsDoc.absolute_path(name,pathenv)
    else
      return CqlsDoc.doc_filename(name,@@tmplExt[mode],true)
    end
  end

  def CqlsDoc.make_dir(dir)
    tmp=File.expand_path(dir)
    FileUtils.mkdir_p(tmp) unless File.exists? tmp
  end

end
