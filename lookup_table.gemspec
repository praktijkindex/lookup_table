$LOAD_PATH << File.expand_path('../lib', __FILE__)

require  'lookup_table/version'

Gem::Specification.new do |s|
  s.name = 'lookup_table'
  s.version = LookupTable::VERSION
  s.summary = 'database fed lookup table'
  s.description = 'use database table as a hash table'
  s.author = 'Artem Baguinski'
  s.email = 'femistofel@gmail.com'
  s.homepage = 'https://github.com/artm/lookup_table'
  s.license = 'MIT'

  s.files = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activerecord', '~> 3.2.18'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3'
end

