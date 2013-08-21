require 'jl4rb'
require 'R4rb'

module Dyndoc
	
	class Vector < Array

		## global stuff
		@@all={}

		def Vector.get
			@@all
		end

		## object stuff
		attr_accessor :vectors
		

		def initialize(langs=[:r])
			@vectors={}
			super()
			if langs.include? :r
				Array.initR 
				@vectors[:r]=R4rb::RVector.new ""
				@vectors[:r] << ids(:r)
			end
			if langs.include? :jl
				Julia.init 
				@vectors[:jl]=Julia::Vector.new ""
				@vectors[:jl] << ids(:jl)
			end

			# global register => callable for update 
			@@all[ids(:rb)]=self
			# first init
			@unlock=true
		end

		def inspect
			"Dyndoc::Vector"+super
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
				 "Dyndoc::Vector.get[\""+ids(:rb)+"\"]"
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
				@vectors[from] > self unless from==:rb
				([:jl,:r]-[from]).each do |to|
					## puts "rb sync (to #{to})"
					@vectors[to] < self
				end
				@unlock=true
			end
		end

		# when modified from ruby, other languages are updated
		def []=(key,val)
			super
			sync
			self
		end


		def replace(ary)
			super(ary)
			sync
			self
		end


	end

end 