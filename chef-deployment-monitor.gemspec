# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name              = 'chef-deployment-monitor'
  s.version           = '1.2.2'
  s.platform          = Gem::Platform::RUBY
  s.has_rdoc          = false
  s.extra_rdoc_files  = ['LICENSE']
  s.authors           = ['Sander Botman', 'Grégoire Seux']
  s.email             = ['g.seux@criteo.com']
  s.homepage          = 'https://github.com/kamaradclimber/chef-deployment-monitor'
  s.summary           = 'Chef Monitoring tool to monitor all changes made'
  s.description       = s.summary
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables       = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths     = ['lib']
  s.license           = 'Apache 2.0'
  s.add_dependency 'file-tail', '>= 1.0.12'
  s.add_dependency 'daemons', '>= 1.1.9'
  s.add_dependency 'mixlib-config'
  s.add_dependency 'json'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubocop'
end
