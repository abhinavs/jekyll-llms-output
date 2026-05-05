# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "pathname"

require "jekyll"
require "jekyll-llms-output"

FIXTURE_SITE = File.expand_path("fixtures/site", __dir__)

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  Jekyll.logger.log_level = :error
end

def build_site(overrides = {})
  dest = Dir.mktmpdir("jlt-dest-")
  config_overrides = {
    "source"      => FIXTURE_SITE,
    "destination" => dest,
    "quiet"       => true,
  }.merge(overrides)
  config = Jekyll.configuration(config_overrides)
  site = Jekyll::Site.new(config)
  site.process
  [site, Pathname.new(dest)]
end

def read_dest(dest, *parts)
  File.read(dest.join(*parts))
end
