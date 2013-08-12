require 'dyndoc/V3/base/helpers/core'

Dir[File.join(File.dirname(__FILE__),"helpers/**/*.rb")].each{|lib|
  require lib unless File.basename(lib,".rb")=="core"
}

