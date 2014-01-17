=begin
TODO: 
1) reprendre tous les types de blocs dyn et nettoyer les blocs nécessitant aucune balise xml! 
ex: [#r]  ... [#rb] ...
%RVERB{
%RVERB}
2) les =&gt; ,... sont à modifier dans les calls :{nom()}
3) idem dans les parties R, ruby
4) les fins de ligne, de pages sont aussi à nettoyer

t.content_xml.root.elements['office:body/*'].to_s.split(/(\[[@#]+[a-z,A-Z]*\])/)  
=end


require 'fileutils'

module CqlsDoc

  class ODT

    MODEL_PATH="dyndoc/share/"

    # *) create dyn helpers to create simple text
    # *) create a simple document
    # *) create methods to extract content from an existing openoffice writer document file and import it inside the document!

    attr_accessor :content, :styles, :jar
    attr_accessor :content_raw, :content_dyn, :content_xml
    attr_accessor :styles_raw, :styles_dyn, :styles_xml

    def initialize(filename)
      @filename = filename
      require 'zip'
      @jar = Zip::ZipFile.open(@filename)
      return true
    end

    def extract_content
      # Read the raw files
      @content_raw = xml_text(@content_xml=xml_doc('content.xml'))
      @styles_raw = xml_text(@styles_xml=xml_doc('styles.xml'))
    end

    def compile
      
      @content_dyn = self.dynify(@content_raw)
      @styles_dyn = self.dynify(@styles_raw)

      # Create 'documatic/master/' in zip file
      self.jar.find_entry('dyndoc/master') || self.jar.mkdir('dyndoc/master')
      
      self.jar.get_output_stream('dyndoc/master/content.dyn') do |f|
        f.write @content_dyn
      end
      self.jar.get_output_stream('dyndoc/master/styles.dyn') do |f|
        f.write @styles_dyn
      end
    end

    def process(local_assigns = {})
      # Compile this template, if not compiled already.
      self.jar.find_entry('dyndoc/master') || self.compile
      # Process the main (body) content.
      @content = ODComponent.new( self.jar.read('dyndoc/master/content.dyn') )
      @content.process(local_assigns)
    end

    def save
=begin
      # Gather all the styles from the partials, add them to the master's styles.
      # Put the body into the document.
      self.jar.get_output_stream('content.xml') do |f|
        f.write self.content.to_s
      end

      if self.styles
        self.jar.get_output_stream('styles.xml') do |f|
          f.write self.styles.to_s
        end
      end
=end
      File.open("content.dyn","w") do |f|
        f << @content_dyn
      end
    end

    def close
      self.jar.close
    end

    protected

    def xml_doc(filename)
      REXML::Document.new(self.jar.read(filename))
    end

    def xml_text(xml_doc)
      xml_text = String.new
      xml_doc.write(xml_text, 0)
      return xml_text
    end

    def dynify(code)
      code.gsub(/(&gt;)/,">") 
    end

  end
end

#t.save
#t.close
=begin
def save
      # Gather all the styles from the partials, add them to the master's styles.
      # Put the body into the document.
      self.jar.get_output_stream('content.xml') do |f|
        f.write self.content.to_s
      end

      if self.styles
        self.jar.get_output_stream('styles.xml') do |f|
          f.write self.styles.to_s
        end
      end
    end

def merge_partial_styles(partials)
      styles = self.xml.root.elements['office:automatic-styles']
      if styles
        partials.each do |partial|
          partial.styles.each_element do |e|
            styles << e
          end
        end
      end
    end
=end
