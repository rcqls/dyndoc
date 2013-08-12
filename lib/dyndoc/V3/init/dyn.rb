# Goal: same purpose than dyn but used without external files.

######################## common tasks for dyn

# each option have to be set in dyn using cmdparse and in some ruby script by calling some function called dyn with first argument a string to be parsed and the rest corresponding to the same options as the script dyn.

# change global variables replaced by one config variable

require "dyndoc/V1+/init/dyn"
require "dyndoc/V3/init/document"
require 'fileutils'


module CqlsDoc

  module V3

  class Dyn

    attr_accessor :tmpl, :cfg, :name, :tmpl_doc
    
    @@cfg={
      :version=>:V3,
      :filename_client => {:name=>"",:basename=>"",:dirname=>""},#name given on the client side!
      :working_dir => "", #directory where dyndoc is processed
      :dyndoc_mode => :normal, #default mode, alternative modes :local_server, :remote_server
      :filename_tmpl=>"", #be specified later
      :filename_tmpl_orig=>"", #be specified later
      :dirname_docs=>"", #default directory unless specified by doc! 
      :rootDoc=>"",
      :user_input=>[],
      :tag_tmpl=>[], #old part_tag!
      :keys_tmpl=>[],
      :docs=>[], #this one is introduced from version V3 to deal with multidocuments 
      :doc_list=>[], #list of documents if nonempty
      :cmd=>[], #list of commands if nonempty for every document
      :cmd_pandoc_options => [], #pandoc options
      :dtag=>:dtag,
      :dtags=>[:dtag],
      :raw_mode=>false,
      :model_tmpl=>"default",
      :model_doc=>"default",
      :append => "",
      :verbose => false,
      :debug => false,
      :pdfviewer=>"xpdf",
      :pngviewer=>"display",
      :docfile=>"DynDoc.pdf",
      :backup => false,
      :backup_home => File.join(CqlsDoc.cfg_dir[:home],"backup"),
      :backup_format => :hour #could be :day, :hour, :min, :sec
    }
    include CqlsDoc::DynConfig
    include CqlsDoc::DynAction

    def initialize(cfg=nil) 
      init_cfg(cfg)
    end

    ## we can reinit cfg  using this method
    def init_cfg(cfg=nil)
      @cfg=@@cfg.dup
      append_cfg(cfg) if cfg #used only inside ruby script
      #p @cfg
    end


# init ##########################################
# TODO: maybe let the user define in some config file
# the way he wants to load some package! Indeed, even if these preloads are generally very useful, they are mostly related to french user (and in particular our).
#The concept of model is user related but we need to think about it more deeply.
# RMK: split the init with respect the :out (that I can change to @cfg[:output])!
    def init(with_doc=true,cfg=nil)
      init_cfg(cfg) if cfg #reinit cfg first if cfg specified! 
      #puts "old";p @cfg[:old]
      @cfg[:rootDoc]=CqlsDoc.init_rootDoc('V3')
      #p @cfg[:rootDoc]
      unless @tmpl
        require 'dyndoc/V3'
        @tmpl=CqlsDoc::V3::TemplateManager.new(@cfg,true)
      else
        @tmpl.tmpl_cfg=@cfg
      end
      #p @cfg
      @tmpl_doc=with_doc ? CqlsDoc::TemplateDocument.new(@cfg) : CqlsDoc::TemplateContentOnlyDocument.new(@tmpl,@cfg) 
      @tmpl.cfg_tmpl=@cfg #same config as @tmpl
#p @cfg
    end

  end

  end
end
