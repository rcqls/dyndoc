# include("ruby.jl")

module Dyndoc

import Base.setindex!,Base.getindex,Base.IO
importall Ruby

export DynVector,DynArray,getindex,setindex!,show,Vector,sync

# this is just a wrapper of Vector type with update of all connected vectors
# when change on the vector occurs  

type DynVector
	ary::Vector
	key::ASCIIString

	DynVector(a::Vector,k::ASCIIString)=(x=new();x.ary=a;x.key=k;x)
end

getindex(dynvect::DynVector,i::Integer)=dynvect.ary[i]

function setindex!(dynvect::DynVector,value,i::Integer)
	dynvect.ary[i]=value
	## println("inisde vect:",Ruby.alive())
	if Ruby.alive() Ruby.run("Dyndoc::Vector[\""*dynvect.key*"\"].sync(:jl)") end
end

show(io::IO,dynvect::DynVector)=show(io,dynvect.ary)

# gather all the julia vectors connected to dyndoc.

type DynArray
	vars::Dict

	DynArray()=(x=new();x.vars=Dict();x)
end

global const Vector=DynArray()

getindex(dynary::DynArray,key::ASCIIString)=dynary.vars[key]

function setindex!(dynary::DynArray,value,key::ASCIIString)
	#println("key:" * key)
	#println(keys(dynary.vars))
	if(haskey(dynary.vars,key))
		#println("haskey" * key)
		dynary.vars[key].ary=value
	else
		dynary.vars[key]=DynVector(value,key)
	end

	## println("inside array:",Ruby.alive())
	
	if Ruby.alive()
		Ruby.run("Dyndoc::Vector[\""*key*"\"].sync(:jl)")
	end
end

sync(dynary::DynArray,key::ASCIIString)= if Ruby.alive() Ruby.run("Dyndoc::Vector[\""*key*"\"].sync(:jl)") end

show(io::IO,dynary::DynArray)=show(io,dynary.vars)

end