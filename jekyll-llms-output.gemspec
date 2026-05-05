# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll-llms-output/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-llms-output"
  spec.version       = Jekyll::LlmsOutput::VERSION
  spec.authors       = ["Abhinav Saxena"]
  spec.email         = ["abhinav061@gmail.com"]

  spec.summary       = "Generate /llms.txt and /llms-full.txt for a Jekyll site."
  spec.description   = <<~DESC
    A Jekyll plugin that writes /llms.txt (an index following llmstxt.org)
    and /llms-full.txt (a concatenated full-text dump of your content).
    Supports a hand-curated _data/llms.yml structure or auto-generation
    from configured collections.
  DESC
  spec.homepage      = "https://github.com/abhinavs/jekyll-llms-output"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "homepage_uri"          => spec.homepage,
    "source_code_uri"       => "#{spec.homepage}/tree/main",
    "bug_tracker_uri"       => "#{spec.homepage}/issues",
    "changelog_uri"         => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true",
  }

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "jekyll", ">= 3.7", "< 5.0"

  spec.add_development_dependency "kramdown-parser-gfm", "~> 1.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
end
