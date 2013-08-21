# include("ruby.jl")

module Dyndoc

import Base.setindex!,Base.getindex
importall Ruby

export DynVector,DynArray,getindex,setindex!

# this is just a wrapper of Vector type with update of all connected vectors
# when change on the vector occurs  

type DynVector
	ary::Vector

	DynVector(a::Vector)=(x=new();x.ary=a;x)
end

getindex(dynvect::DynVector,i::Integer)=dynvect.ary[i]

function setindex!(dynvect::DynVector,value,i::Integer)
	dynvect.ary[i]=value
	println("inisde vect")
	if Ruby.alive() Ruby.run("Dyndoc::Vector.get[\""*key*"\"].sync(:jl)") end
end


# gather all the julia vectors connected to dyndoc.

type DynArray
	vars::Dict

	DynArray()=(x=new();x.vars=Dict();x)
end

global _dynArray=DynArray()

getindex(dynary::DynArray,key::String)=dynary.vars[key]

function setindex!(dynary::DynArray,value,key::ASCIIString)
	dynary.vars[key]=DynVector(value)
	println("inisde array")
	if Ruby.alive() Ruby.run("Dyndoc::Vector.all[\""*key*"\"].sync(:jl)") end
end

end