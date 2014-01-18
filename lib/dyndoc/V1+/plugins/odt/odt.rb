require 'rexml/document'
require 'rexml/attribute'

# Comment on the styles:
# in documatic, each partial has their own style prefixed in order to be compatible with the styles of the master document.
# in dyn: the notion of styles will be more global! The styles have to be considered more globally and each template has to use the same style. Then, there is no merging styles stage as it is done in documatic!
# Rmk: maybe this is not applicable because it is required by openoffice which chooses automatically the name of the style!
# But it seems that one could define predefined styles in openoffice
# In fact! It is maybe the difference between automatic-style in the content file and the styles.xml content!
# It is then necessary to merge the automatic-styles as it done in documatic!

module CqlsDoc

  class Odt
    attr_accessor :filename, :ar, :content_text, :styles_text, :content_xml, :styles_xml, :automatic_styles, :xlink_href

    def initialize(filename)
      @filename = filename
      require (RUBY_VERSION <= "1.8.7" ? 'zip/zip' : 'zip')
      @ar = Zip::ZipFile.open(@filename)
      extract
      @prefix=File.basename(@filename, '.odt').gsub(/[^A-Za-z0-9_]/,'_')
      init_content
    end

    def extract
      # Read the raw files
      @content_text = xml_text(@content_xml=xml_doc('content.xml'))
      @styles_text = xml_text(@styles_xml=xml_doc('styles.xml'))
    end

    def complete_xlink_href(key,new_key)
      if @ar.find_entry(key)
	@xlink_href[key]=new_key
      else 
	@ar.entries.each{|e| 
	if (path=e.name.split("/"))[0]==key
	  @xlink_href[e.name]=([new_key]+path[1..-1]).join("/")
	end
	}
      end
    end
    
    def init_content
      if @prefix

	# Remy: prepend prefix for every attributes with name ":name" 
	@content_xml.each_element('//office:body//*') {|e| 
	  e.attributes.each_attribute{|attr|
	    e.add_attribute(attr.expanded_name, "#{@prefix}_#{attr.value}") if attr.expanded_name[-5..-1]==":name"
	  }
	}

	# Management of objects with attributes xlink:href
	@xlink_href = {}
	@content_xml.each_element('//office:body//*') {|e| 
	  e.attributes.each_attribute{|attr| 
	    if attr.expanded_name=="xlink:href"
	      k=attr.value.gsub(/^\.\//,"")
	      a=k.split("/")
	      # update @xlink_ref which refers to the real ressources used when creating the master document (make_odt_ressources)
	      complete_xlink_href(k,new_k=(a[0...-1]+[@prefix+"_"+a[-1]]).join("/"))
	      # update the content with this new prefixed attribute
	      e.add_attribute(attr.expanded_name, new_k)
	    end 
	  }
	}
	# only the name of xlink:ref have been changed! Files are then updated in the master document thank to @xlink_href!

	# Management of the style:name
	style_names = {}

	# From documatic: Gather all auto style names from <office:automatic-styles>
	@content_xml.root.each_element('office:automatic-styles/*') do |e|
	  attr = e.attributes.get_attribute('style:name')
	  attr && style_names[attr.value] = attr
	end

	# From documatic: Replace all auto styles in the document's attributes with the
	# prefixed form.
      
	@content_xml.each_element('//*') do |e|
	  e.attributes.each_attribute do |attr|
	    if style_names.has_key? attr.value
	      e.add_attribute(attr.expanded_name, "#{@prefix}_#{attr.value}")
	    end
	  end
	end
	@automatic_styles = @content_xml.root.elements['office:automatic-styles']
      end
    end

    def body_from_content
      body_text = @content_xml.root.elements['office:body/office:text']
      body_text.elements.delete('text:sequence-decls')
      body_text.elements.delete('office:forms')
      body_text.elements.to_a.collect{|e| e.to_s }.join("\n")
    end

    protected

    def xml_doc(filename)
      REXML::Document.new(@ar.read(filename))
    end

    def xml_text(xml_doc)
      xml_text = String.new
      xml_doc.write(xml_text, 0)
      return xml_text
    end

  end

end
