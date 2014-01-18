#!/usr/bin/env ruby
require 'ostruct'
require 'optparse'
require 'tilt'

dynlib_path=nil
# The two first paths are for devel mode (the second one is maybe obsolete)
# The two last paths are for production mode (the last one is closed to be abandonned)
[["Dropbox","Dyndoc","System","dyndoc.ruby"],["DyndocVB","SharedFolder","System","dyndoc-ruby"],["DyndocVB","System","dyndoc.ruby"],[".gPrj","work","dyndoc.ruby"]].each {|prefix|
  dynlib_path=Dir[File.join(ENV["HOME"],prefix,"lib")][0] unless dynlib_path
}
$:.unshift(dynlib_path) if  dynlib_path

require 'dyndoc/common/tilt'

Tilt::DynDocTemplate.init <<-DynDocLibs
  Tools/Web/TabBar
  Tools/Web/JQueryTools
  Tools/Web/DHtmlX
  Tools/Web/Code
  Tools/Web/Ace
  Tools/Web/Html
  Tools/Web/Html/Styles
  Tools/Web/Html/JQuery
  Tools/Web/Layout
  Tools/Tex/Tools
  DynDocLibs

usage = <<USAGE
Usage: dyndoc-tilt <options> <file>
Process template <file> and write output to stdout. With no <file> or
when <file> is '-', read template from stdin and use the --type option
to determine the template's type.

Options
  -l, --list           List template engines + file patterns and exit
  -t, --type=<pattern> Use this template engine; required if no <file>
  -y, --layout=<file>  Use <file> as a layout template

  -D<name>=<value>     Define variable <name> as <value>
  --vars=<ruby>        Evaluate <ruby> to Hash and use for variables

  -h, --help           Show this help message

Convert markdown to HTML:
  $ dyndoc-tilt foo.markdown > foo.html

Process ERB template:
  $ echo "Answer: <%= 2 + 2 %>" | tilt -t erb
  Answer: 4

Define variables:
  $ echo "Answer: <%= 2 + n %>" | tilt -t erb --vars="{:n=>40}"
  Answer: 42
  $ echo "Answer: <%= 2 + n.to_i %>" | tilt -t erb -Dn=40
  Answer: 42
USAGE

script_name = File.basename($0)
pattern = nil
layout = nil
locals = {}

ARGV.options do |o|
  o.program_name = script_name

  # list all available template engines
  o.on("-l", "--list") do
    groups = {}
    Tilt.mappings.each do |pattern,engines|
      engines.each do |engine|
        key = engine.name.split('::').last.sub(/Template$/, '')
        (groups[key] ||= []) << pattern if pattern =~ /^dyn/ # to restrict 
      end
    end
    groups.sort { |(k1,v1),(k2,v2)| k1 <=> k2 }.each do |engine,files|
      printf "%-15s %s\n", engine, files.sort.join(', ')
    end
    exit
  end

  # the template type / pattern
  o.on("-t", "--type=PATTERN", String) do |val|
    abort "unknown template type: #{val}" if Tilt[val].nil?
    pattern = val
  end

  # pass template output into the specified layout template
  o.on("-y", "--layout=FILE", String)  do |file|
    paths = [file, "~/.tilt/#{file}", "/etc/tilt/#{file}"]
    layout = paths.
      map  { |p| File.expand_path(p) }.
      find { |p| File.exist?(p) }
    abort "no such layout: #{file}" if layout.nil?
  end

  # define a local variable
  o.on("-D", "--define=PAIR", String) do |pair|
    key, value = pair.split(/[=:]/, 2)
    locals[key.to_sym] = value
  end

  # define local variables using a Ruby hash
  o.on("--vars=RUBY") do |ruby|
    hash = eval(ruby)
    abort "vars must be a Hash, not #{hash.inspect}" if !hash.is_a?(Hash)
    hash.each { |key, value| locals[key.to_sym] = value }
  end

  o.on_tail("-h", "--help") { puts usage; exit }

  o.parse!
end

file = ARGV.first || '-'
pattern = (file and ([".dyn",".dyn_html",".dyn_txtl",".dyn_ttm"].include?(ext=File.extname(file)) ? ext[1..-1] : "dyn" )) if pattern.nil?
abort "template type not given. see: #{$0} --help" if ['-', ''].include?(pattern)

engine = Tilt[pattern]
abort "template engine not found for: #{pattern}" if engine.nil?

template =
  engine.new(file) {
    if file == '-'
      $stdin.read
    else
      File.read(file)
    end
  }
output = template.render(self, locals)

# process layout
output = Tilt.new(layout).render(self, locals) { output } if layout

$stdout.write(output)