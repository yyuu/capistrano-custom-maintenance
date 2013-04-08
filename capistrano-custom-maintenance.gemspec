# -*- encoding: utf-8 -*-
require File.expand_path('../lib/capistrano-custom-maintenance/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Yamashita Yuu"]
  gem.email         = ["yamashita@geishatokyo.com"]
  gem.description   = %q{a customizable capistrano maintenance recipe.}
  gem.summary       = %q{a customizable capistrano maintenance recipe.}
  gem.homepage      = "https://github.com/yyuu/capistrano-custom-maintenance"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capistrano-custom-maintenance"
  gem.require_paths = ["lib"]
  gem.version       = Capistrano::CustomMaintenance::VERSION

  gem.add_dependency("capistrano")
  gem.add_dependency("capistrano-file-resources", ">= 0.1.1")
  gem.add_dependency("json")
  gem.add_dependency("mime-types")
  gem.add_development_dependency("capistrano-platform-resources", ">= 0.1.0")
end
