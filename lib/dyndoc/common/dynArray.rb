require 'jl4rb'
require 'R4rb'

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
		attr_accessor :vectors, :ary
		

		def initialize(langs=[:r],ary=[])
			@ary=ary
			@vectors={}
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
		end

		def inspect
			"Dyndoc::Vector"+@ary.inspect
		end

		def ids(lang)
			case lang
			when :rb
				 "rb"+self.object_id.abs.to_s
			when :jl
				"_dynArray.vars[\"rb"+self.object_id.abs.to_s+"\"].ary"
			when :r
				".dynArray$vars[[\"rb"+self.object_id.abs.to_s+"\"]]"
			end
		end

		def wrapper(lang)
			case lang
			when :rb
				 "Dyndoc::Vector[\""+ids(:rb)+"\"]"
			when :jl
				"_dynArray[\"rb"+self.object_id.abs.to_s+"\"]"
			when :r
				".dynArray[[\"rb"+self.object_id.abs.to_s+"\"]]"
			end
		end

		# from is :rb, :jl or :r
		def sync(from=:rb)
			if @unlock
				@unlock=nil #to avoid the same update several times
				## puts "rb sync (from #{from}):"+ids(:rb)
				@vectors[from] > @ary unless from==:rb
				([:jl,:r]-[from]).each do |to|
					## puts "rb sync (to #{to})"
					@vectors[to] < @ary
					## p @vectors[to].value
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