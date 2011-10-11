# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redis/ring/version"

Gem::Specification.new do |s|
  s.name        = "redis-ring"
  s.version     = RedisRing::VERSION
  s.authors     = ["Todd Fisher"]
  s.email       = ["todd.fisher@livingsocial.com"]
  s.homepage    = "http://livingsocial.com/"
  s.summary     = %q{HashRing to buckets not severs}
  s.description = %q{HashRing to intermediate buckets allowing you to more easily scale out to more severs later}

  s.rubyforge_project = "redis-ring"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
#  s.add_development_dependency "rails"

  s.add_runtime_dependency "json"
  s.add_runtime_dependency "active_support"
  s.add_runtime_dependency "redis"
  s.add_runtime_dependency "redis-namespace"
end
