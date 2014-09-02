#require 'jl4rb'
#require 'R4rb'

# Since more than one language is used for Array transfert
# This stuff is moved from R4rb package to here
# => Undone because R4rb is not self-content
# => methods :> and :< overloaded from R4rb

class Array

	## Already in R4rb and still there to be self-contents
	# def rb2R=(mode=nil)
	# 	##puts "rb2R mode #{object_id}";p mode
	# 	mode=R4rb unless mode
	# 	return if @rb2R_mode and @rb2R_mode==mode
	# 	@rb2R_mode=mode unless @rb2R_mode
	# 	@rb2R=(@rb2R_mode==Rserve ? Rserve::RVector.new("") :  R2rb::RVector.new("") )
	# 	##puts "rb2R=";p @rb2R
	# end

	def rb2jl! #only one mode
		@rb2jl= Julia::Vector.new("") 
		##puts "rb2jl=";p @rb2jl
	end
	# out is a String representing a R or Julia expression 

	def >(out)
		out.strip!
		mode=:r 
		#out represents here an R or Julia object
		if out =~ /^jl\:/
			mode,out=:jl,out[3..-1]
		elsif out =~ /^(r|R)\:/
			out=out[2..-1]
		end
		case mode
		when :r
		    self.rb2R=nil unless @rb2R
		    @rb2R << out
		    @rb2R < self
		when :jl
			self.rb2jl=nil unless @rb2jl
		    @rb2jl << out
		    @rb2jl < self
		end
	    return self
	end

	def <(out) #out represents here an R or Julia expression to execute and put inside the Array
	    out.strip!
		mode=:r 
		#out represents here an R or Julia object
		if out =~ /^jl\:/
			mode,out=:jl,out[3..-1]
		elsif out =~ /^(r|R)\:/
			out=out[2..-1]
		end
		case mode
		when :r
	    	self.rb2R=nil unless @rb2R
	    	@rb2R << out
	    	@rb2R > self
	    when :jl
	    	self.rb2jl! unless @rb2jl
	    	@rb2jl << out
	    	@rb2jl > self
	    end
	    	
	    return self
	end

end


## Dyndoc Array : ruby Array synchronized to Julia or R Vector
# when change occurs from any language
module Dyndoc
	
	class Vector

		## global stuff
		@@all={}

		def Vector.get
			@@all
		end

		def Vector.[](key)
			@@all[key]
		end

		def Vector.[]=(key,value)
			@@all[key].replace(value) if value.is_a? Array
			@@all[key]
		end

		## object stuff
		attr_accessor :vectors, :ary, :id
		
		# ary is a String when lang is not :rb
		def initialize(langs=[:r],first=[],lang=:rb,vname=nil)
			@ary=(first.is_a? String) ? [] : first
			@vectors={}
			@vname,@id=vname,vname+"@"+self.object_id.abs.to_s
			if langs.include? :r
				Array.initR 
				@vectors[:r]=R4rb::RVector.new ""
				@vectors[:r] << ids(:r)
				@vectors[:r] < @ary unless @ary.empty?
			end
			if langs.include? :jl
				Julia.init 
				@vectors[:jl]=Julia::Vector.new ""
				@vectors[:jl] << ids(:jl)
				Julia << wrapper(:jl)+"=Any[]"
				@vectors[:jl] < @ary unless @ary.empty?
			end
			# global register => callable for update 
			@@all[ids(:rb)]=self
			# first init
			@unlock=true
			case lang
			when :jl
				Julia << ids(:jl)+"="+first
				sync(:jl)
				## Julia << "println("+wrapper(:jl)+")"
			when :r,:R
				R4rb << ids(:r)+"<-"+first
				sync(:r)
				## R4rb << "print("+wrapper(:r)+")"
			end
		end

		def inspect
			"Dyndoc::Vector"+@ary.inspect
		end

		def ids(lang)
			case lang
			when :rb
				 @id
			when :jl
				"Dyndoc.Vector[\""+@id+"\"].ary"
			when :r
				".dynArray[[\""+@id+"\"]]"
			end
		end

		def wrapper(lang)
			case lang
			when :rb
				 "Dyndoc::Vector[\""+@id+"\"]"
			when :jl
				"Dyndoc.Vector[\""+@id+"\"]"
			when :r
				".dynArray[[\""+@id+"\"]]"
			end
		end

		# from is :rb, :jl or :r
		def sync(from=:rb)
			if @unlock
				@unlock=nil #to avoid the same update several times
				## Dyndoc.warn "rb sync (from #{from}):",ids(:rb)
				@vectors[from] > @ary unless from==:rb
				## 
				Dyndoc.warn "new ary",[@vectors[from].name,@vectors[from].value,@ary]
				([:jl,:r]-[from]).each do |to|
					## Dyndoc.warn "rb sync (to #{to})"
					@vectors[to] < @ary
					## Dyndoc.warn "@vectors[#{to}].value", @vectors[to].value
				end
				@unlock=true
			end
		end

		def [](key)
			@ary[key]
		end

		# when modified from ruby, other languages are updated
		def []=(key,val)
			@ary[key]=val #super
			sync
			self
		end


		def replace(ary)
			@ary.replace ary #super ary
			sync
			self
		end


	end

end 