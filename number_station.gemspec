require 'rubygems'
require 'rake'

Gem::Specification.new do |s|
  s.name        = 'number_station'
  s.version     = '0.0.1'
  s.date        = '2018-10-12'
  s.summary     = "number_station - run your own number station!"
  s.description = "A collection of utilities to aid in running your own number station!"
  s.authors     = ["David Kirwan"]
  s.email       = ['davidkirwanirl@gmail.com']
  s.require_paths = ["lib"]
  s.files       = FileList['lib/**/*.rb',
                      'bin/*',
                      '[A-Z]*',
                      'resources/*',
                      'test/**/*'].to_a
  s.homepage    = 'http://rubygems.org/gems/number_station'
  s.required_ruby_version = '>= 2.0.0'
  s.executables << 'number_station'
  s.license 	= 'GPL 3.0'

  s.add_development_dependency "bundler"
  s.add_development_dependency "test-unit"
end
