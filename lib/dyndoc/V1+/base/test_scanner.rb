require 'scanner'

class TagScanner < CqlsDoc::Scanner
    @@type[:tag]={
          :start=>/\(/,
          :stop=> /\)/,
          :mode=>{:start=>-1,:stop=>0,:length=>1},
        }
    
    def initialize(type=:tag,start=nil,stop=nil,mode=nil,escape=nil)
      super
      @type_stop_filter="#!"
    end

  end

scan=TagScanner.new


str="((toto:test|test2) & (toto2:titi)) | (toto2:test3)"
scan.tokenize(str)
p scan.extract