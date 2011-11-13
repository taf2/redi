# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redi/version"

Gem::Specification.new do |s|
  s.name        = "redi"
  s.version     = Redi::VERSION
  s.authors     = ["Todd Fisher", "Ben Bleything"]
  s.email       = ["todd.fisher@livingsocial.com", "ben@bleything.net"]
  s.homepage    = "http://livingsocial.com/"
  s.summary     = %q{Redi multi redis scaling "to infinity and beyond!"}
  s.description = %q{hash keys to intermediate buckets allowing you to more easily scale out to more severs later}

  s.rubyforge_project = "redi"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rake"

  s.add_runtime_dependency "redis",           '>= 2.2.0'
  s.add_runtime_dependency "redis-namespace", '>= 1.1.0'
end
