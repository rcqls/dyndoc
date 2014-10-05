require File.join(File.dirname(__FILE__),"../mrblib/dyndoc.rb")

txt='{#document][#main][#>]toto[TOTO][#>]<<<\
	titééi #{toto}\
	[#?]#{+?toto}[#>]PLUS\
	[#?]#{=toto} == "TOTO"[#>]PLUS2\
	[#rb<]@tata="joe"\
[#nl][#>]tata is :{@tata}[#nl]\
{#case]:{@tata},#{toto},joe\
[#when]joe[#>]I am JOE\
[#when]TOTO[#>]I am Toto\
[#case}\
	>>>[#}'

txt='{#document][#main][#>]toto[TOTO][#>]<<<
	titééi #{toto}
	[#?]#{+?toto}[#>]PLUS
	[#?]#{=toto} == "TOTO"[#>]PLUS2
	[#rb<]$tata="Joe";p [:ici,$tata]
	[#nl][#>]tata is :{$tata} :{:tata.to_s.capitalize}[#nl]
	{#case]#{toto},joe
	[#when]joe[#>]I am JOE
	[#when]TOTO[#>]I am Toto
	[#case}
	>>>[#}'



mngr = Dyndoc::MRuby::TemplateManager.new({},false)
p mngr
mngr.init_doc({})

a=mngr.parse(txt)
#puts ""
puts a
