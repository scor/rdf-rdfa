#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version               = File.read('VERSION').chomp
  gem.date                  = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name                  = %q{rdf-rdfa}
  gem.homepage              = "http://ruby-rdf.github.com/rdf-rdfa"
  gem.license               = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary               = "RDFa reader/writer for RDF.rb."
  gem.description           = "RDF::RDFa is an RDFa reader/writer for Ruby using the RDF.rb library suite."
  gem.rubyforge_project     = 'rdf-rdfa'

  gem.authors               = %w(Gregg Kellogg)
  gem.email                 = 'public-rdf-ruby@w3.org'

  gem.platform              = Gem::Platform::RUBY
  gem.files                 = %w(AUTHORS README UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.require_paths         = %w(lib)
  gem.has_rdoc              = false

  gem.required_ruby_version = '>= 1.8.7'
  gem.requirements          = []

  gem.add_runtime_dependency     'rdf',             '>= 1.0.5'
  gem.add_runtime_dependency     'haml',            '>= 4.0'
  gem.add_runtime_dependency     'rdf-xsd',         '>= 1.0'
  gem.add_runtime_dependency     'htmlentities',    '>= 4.3.1'
  gem.add_runtime_dependency     'backports'                    if RUBY_VERSION < "1.9"
  
  gem.add_development_dependency 'nokogiri' ,       '>= 1.5.9'
  gem.add_development_dependency 'equivalent-xml' , '>= 0.3.0'
  gem.add_development_dependency 'open-uri-cached', '>= 0.0.5'
  gem.add_development_dependency 'json-ld',         '>= 0.9.1'
  gem.add_development_dependency 'rspec',           '>= 2.14.0'
  gem.add_development_dependency 'rdf-microdata'
  gem.add_development_dependency 'rdf-spec',        '>= 1.0'
  gem.add_development_dependency 'rdf-turtle'
  gem.add_development_dependency 'rdf-rdfxml'
  gem.add_development_dependency 'rdf-isomorphic'
  gem.add_development_dependency 'sparql'
  gem.add_development_dependency 'yard' ,           '>= 0.8.5'
  gem.post_install_message  = nil
end

