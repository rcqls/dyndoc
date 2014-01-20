module CqlsDoc

  SOFTWARE={}

  def CqlsDoc.software_init

    unless SOFTWARE[:R]
      if RUBY_VERSION=~/mingw32/
        cmd=Dir[File.join(ENV["HomeDrive"],"Program Files","R","**","R.exe")]
        SOFTWARE[:R]=cmd[0] unless cmd.empty?
      else
        cmd=`type "R"`
        SOFTWARE[:R]=cmd.strip.split(" ")[2] unless cmd.empty?
      end
    end

    unless SOFTWARE[:Rscript]
      if RUBY_VERSION=~/mingw32/
        cmd=Dir[File.join(ENV["HomeDrive"],"Program Files","R","**","Rscript.exe")]
        SOFTWARE[:Rscript]=cmd[0] unless cmd.empty?
      else
        cmd=`type "Rscript"`
        SOFTWARE[:R]=cmd.strip.split(" ")[2] unless cmd.empty?
      end
    end

    unless SOFTWARE[:ruby]
      cmd=`type "ruby"`
      SOFTWARE[:pdflatex]=cmd.strip.split(" ")[2] unless cmd.empty?
    end
     
    unless SOFTWARE[:pdflatex]
      cmd=`type "pdflatex"`
      SOFTWARE[:pdflatex]=cmd.strip.split(" ")[2] unless cmd.empty?
    end
    
    unless SOFTWARE[:pandoc]
      if File.exist? File.join(ENV["HOME"],".cabal","bin","pandoc")
        SOFTWARE[:pandoc]=File.join(ENV["HOME"],".cabal","bin","pandoc")
      else
        cmd = `which pandoc`.strip
        SOFTWARE[:pandoc]=cmd unless cmd.empty?
        #cmd=`type "pandoc"`
        #SOFTWARE[:pandoc]=cmd.strip.split(" ")[2] unless cmd.empty?
      end
    end
  
    unless SOFTWARE[:ttm]
      cmd=`type "ttm"`
      SOFTWARE[:ttm]=cmd.strip.split(" ")[2] unless cmd.empty?
    end
     
  end

  def CqlsDoc.software?(software)
    software - SOFTWARE.keys
  end

end