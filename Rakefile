require 'rubygems'
require 'rubygems/package_task'

PKG_NAME='dyndoc-ruby'
PKG_NAME_CLIENT='dyndoc-client'
PKG_NAME_SERVER='dyndoc-server'
PKG_NAME_VM='dyndoc-vm'
PKG_VERSION='1.6.0'

PKG_FILES=FileList[
    'bin/dyndoc-ruby',
    'bin/dyndoc-devel',
    'bin/dyndoc-tilt',
    'bin/dyndoc-envir', # used for windows as a post-install
    'lib/dyndoc/**/*.rb', #not lib/cqlsEM/* lib/dyndocEM
    'dyndoc/**/*',
    'share/odt/**/*',
    'share/julia/**/*',
    'share/R/dynArray.R',
    'dyndoc/**/.*' #IMPORTANT file starting with . are by default ignored!
]

PKG_FILES_CLIENT=FileList[
    'bin/dyndoc-client','bin/dyndoc-client-devel',
    'lib/cqlsEM/*','lib/dyndocEM/dyndoc-client.rb',
    'lib/dyndoc/common/*.rb',
    'share/syntax/**/*'
]

PKG_FILES_SERVER=FileList[
    'bin/dyndoc-server',
    'bin/dyndoc-daemon',
    'lib/dyndoc/**/*.rb', 'lib/cqlsEM/*.rb','lib/dyndocEM/dyndoc-server.rb', #included lib/cqlsEM/*
    'dyndoc/**/*',
    'share/initscript/**/*',
    'share/odt/**/*',
    'dyndoc/**/.*' #IMPORTANT file starting with . are by default ignored!
]

PKG_FILES_VM=FileList[
    'bin/dyndoc-init','bin/dyndoc-vm',
    'lib/dyndoc/common/vbox.rb'
]

spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "R and Ruby in text document"
    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.requirements << 'none'
    s.add_dependency("cmdparse",">=2.0.2")
    s.add_dependency("rubyzip",">=0.9.1")
    s.add_dependency("RedCloth",">=4.2.9")
    s.add_dependency("commander",">=4.1.3")
    s.add_dependency("highline",">=1.6.15")
    s.require_path = 'lib'
    s.files = PKG_FILES.to_a
    s.bindir = "bin"
    s.executables = ["dyndoc-ruby","dyndoc-devel","dyndoc-tilt","dyndoc-envir"]
    s.description = <<-EOF
  Provide templating in text document.
  EOF
    s.author = "CQLS"
    s.email= "rdrouilh@gmail.com"
    s.homepage = "http://cqls.upmf-grenoble.fr"
    s.rubyforge_project = nil
end



spec_client = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "Dyndoc client"
    s.name = PKG_NAME_CLIENT
    s.version = PKG_VERSION
    s.requirements << 'none'
    s.add_dependency("eventmachine",">=0.12.10")
    s.add_dependency("cmdparse",">=2.0.2")
    s.add_dependency("rubyzip",">=0.9.1")
    s.require_path = 'lib'
    s.files = PKG_FILES_CLIENT.to_a
    s.bindir = "bin"
    s.executables = ["dyndoc-client","dyndoc-client-devel"]
    s.description = <<-EOF
  client for dyndoc.
  EOF
    s.author = "CQLS"
    s.email= "rdrouilh@gmail.com"
    s.homepage = "http://cqls.upmf-grenoble.fr"
    s.rubyforge_project = nil
end

spec_server = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "Dyndoc server"
    s.name = PKG_NAME_SERVER
    s.version = PKG_VERSION
    s.requirements << 'none'
    s.add_dependency("eventmachine",">=0.12.10")
    s.add_dependency("cmdparse",">=2.0.2")
    s.add_dependency("rubyzip",">=0.9.1")
    s.add_dependency("daemons",">=1.1.0")
    s.add_dependency("ptools",">=1.2.1")
    s.require_path = 'lib'
    s.files = PKG_FILES_SERVER.to_a
    s.bindir = "bin"
    s.executables = ["dyndoc-server","dyndoc-daemon"]
    s.description = <<-EOF
  server for dyndoc.
  EOF
    s.author = "CQLS"
    s.email= "rdrouilh@gmail.com"
    s.homepage = "http://cqls.upmf-grenoble.fr"
    s.rubyforge_project = nil
end

spec_vm = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "Dyndoc vm"
    s.name = PKG_NAME_VM
    s.version = PKG_VERSION
    s.requirements << 'none'
    s.require_path = 'lib'
    s.files = PKG_FILES_VM.to_a
    s.bindir = "bin"
    s.executables = ["dyndoc-init","dyndoc-vm"]
    s.description = <<-EOF
  client for managing dyndoc inside the vm.
  EOF
    s.author = "CQLS"
    s.email= "rdrouilh@gmail.com"
    s.homepage = "http://cqls.upmf-grenoble.fr"
    s.rubyforge_project = nil
end

## this allows to produce some parameter for task like  Gem::PackageTask (without additional argument!)
opt={};ARGV.select{|e| e=~/\=/ }.each{|e| tmp= e.split("=");opt[tmp[0]]=tmp[1]}

## rake ... pkgdir=<path to provide> to update PKG_INSTALL_DIR
PKG_INSTALL_DIR=opt["pkgdir"] || ENV["RUBYGEMS_PKGDIR"]  || "pkg"

## gem task!!!
desc "Create #{PKG_NAME+'-'+PKG_VERSION+'.gem'}" 
Gem::PackageTask.new(spec) do |pkg|
    pkg.package_dir=PKG_INSTALL_DIR
    pkg.need_zip = false
    pkg.need_tar = false
end

desc "Create #{PKG_NAME_CLIENT+'-'+PKG_VERSION+'.gem'}" 
task :client do |t|
  Gem::Builder.new(spec_client).build
  `mv #{PKG_NAME_CLIENT+'-'+PKG_VERSION+'.gem'} #{PKG_INSTALL_DIR}`
end

desc "Create #{PKG_NAME_SERVER+'-'+PKG_VERSION+'.gem'}" 
task :server do |t|
  Gem::Builder.new(spec_server).build
  `mv #{PKG_NAME_SERVER+'-'+PKG_VERSION+'.gem'} #{PKG_INSTALL_DIR}`
end

desc "Create #{PKG_NAME_CLIENT+'-'+PKG_VERSION+'.gem'}" 
task :vm do |t|
  Gem::Builder.new(spec_vm).build
  `mv #{PKG_NAME_VM+'-'+PKG_VERSION+'.gem'} #{PKG_INSTALL_DIR}`
end

## clean task
desc "Remove #{File.join(PKG_INSTALL_DIR,PKG_NAME+'-'+PKG_VERSION+'.gem')}"
task :clean do |t|
  rm File.join(PKG_INSTALL_DIR,PKG_NAME+'-'+PKG_VERSION+'.gem')
end

## install task with doc
desc "Install #{File.join(PKG_INSTALL_DIR,PKG_NAME+'-'+PKG_VERSION+'.gem')}"
task :install_with_doc do |t|
  `gem install #{File.join(PKG_INSTALL_DIR,PKG_NAME+'-'+PKG_VERSION+'.gem')}`
end

## quick install task
desc "Quick install #{File.join(PKG_INSTALL_DIR,PKG_NAME+'-'+PKG_VERSION+'.gem')}"
task :install do |t|
    `gem install #{File.join(PKG_INSTALL_DIR,PKG_NAME+'-'+PKG_VERSION+'.gem')} --local --no-rdoc --no-ri -i /usr/local/lib/ruby/gems/1.8`
    `gem install #{File.join(PKG_INSTALL_DIR,PKG_NAME_CLIENT+'-'+PKG_VERSION+'.gem')} --local --no-rdoc --no-ri -i /usr/local/lib/ruby/gems/1.8`
    `gem install #{File.join(PKG_INSTALL_DIR,PKG_NAME_SERVER+'-'+PKG_VERSION+'.gem')} --local --no-rdoc --no-ri -i /usr/local/lib/ruby/gems/1.8`
    `gem install #{File.join(PKG_INSTALL_DIR,PKG_NAME_VM+'-'+PKG_VERSION+'.gem')} --local --no-rdoc --no-ri -i /usr/local/lib/ruby/gems/1.8`
end

## quick install task
desc "Quick install #{File.join(PKG_INSTALL_DIR,PKG_NAME_VM+'-'+PKG_VERSION+'.gem')}"
task :installVM do |t|
    `gem install #{File.join(PKG_INSTALL_DIR,PKG_NAME_VM+'-'+PKG_VERSION+'.gem')} --local --no-rdoc --no-ri -i /usr/local/lib/ruby/gems/1.8`
end



