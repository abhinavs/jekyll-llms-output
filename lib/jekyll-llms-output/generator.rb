# frozen_string_literal: true

require "fileutils"

module Jekyll
  module LlmsOutput
    DEFAULTS = {
      "enabled" => true,
      "index" => {
        "enabled"     => true,
        "output"      => "/llms.txt",
        "data"        => "llms",
        "title"       => nil,
        "description" => nil,
        "collections" => ["posts"],
      },
      "full" => {
        "enabled"          => true,
        "output"           => "/llms-full.txt",
        "collections"      => ["posts"],
        "pages"            => false,
        "page_extensions"  => [".md", ".markdown"],
        "separator"        => "\n\n---\n\n",
        "include_url"      => true,
        "include_date"     => true,
        "respect_markdown_output" => false,
      },
    }.freeze

    def self.config_for(site)
      user = site.config["llms_output"] || {}
      merged = deep_merge(DEFAULTS, user)
      merged
    end

    def self.deep_merge(a, b)
      a.merge(b) do |_, av, bv|
        av.is_a?(Hash) && bv.is_a?(Hash) ? deep_merge(av, bv) : bv
      end
    end

    def self.write_all(site)
      config = config_for(site)
      return unless config["enabled"]

      if config["index"]["enabled"]
        body = IndexBuilder.new(site, config["index"]).build
        write_file(site, config["index"]["output"], body)
        Jekyll.logger.info("LlmsOutput:", "wrote #{config["index"]["output"]}")
      end

      if config["full"]["enabled"]
        body = FullBuilder.new(site, config["full"]).build
        write_file(site, config["full"]["output"], body)
        Jekyll.logger.info("LlmsOutput:", "wrote #{config["full"]["output"]}")
      end
    end

    def self.write_file(site, output_path, body)
      path = File.join(site.dest, output_path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, body)
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::LlmsOutput.write_all(site)
end
