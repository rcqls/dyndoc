module CqlsDoc

	# allows to expand subpath of the form 'lib/<dyndoc/tutu/toto' 
	def CqlsDoc.expand_path(filename)
		filename=File.expand_path(filename).split(File::Separator)
		to_find=filename.each_with_index.map{|pa,i| i if pa =~ /^\<[^\<\>]*/}.compact
		return File.join(filename) if to_find.empty?
		to_find=to_find[0]
		path=CqlsDoc.find_subpath_before(File.join(filename[to_find][1..-1],filename[(to_find+1)...-1]),filename[0...to_find])
		return path ? CqlsDoc.expand_path(File.join(path+filename[-1,1])) : nil
	end

	def CqlsDoc.find_subpath_before(subpath,before)
		l=before.length+1
		return [before[0..l],subpath] if File.exists? File.join(before[0..l],subpath) while (l-=1)>=0
		return nil
	end

end