require_relative "lib/backstage/version"

Gem::Specification.new do |spec|
  spec.name = "backstage"
  spec.version = Backstage::VERSION
  spec.authors = ["Gareth James"]
  spec.email = ["g.claude@bemused.org"]
  spec.summary = "A lightweight, configurable admin interface for Rails 8"
  spec.homepage = "https://github.com/gjtorikian/backstage"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir[
    "{app,config,lib}/**/*",
    "LICENSE", "README.md", "CHANGELOG.md", "CONTRIBUTING.md"
  ].reject { |f| File.directory?(f) }

  spec.add_dependency "railties", "~> 8.0"
end
