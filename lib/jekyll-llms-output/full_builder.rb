# frozen_string_literal: true

module Jekyll
  module LlmsOutput
    # Builds the body of /llms-full.txt: a concatenation of every document's
    # source markdown, separated by a configurable delimiter, each with a
    # small header (title + url) for context.
    class FullBuilder
      attr_reader :site, :options

      def initialize(site, options)
        @site = site
        @options = options
      end

      def build
        chunks = []

        Array(options["collections"]).each do |coll_name|
          collection = site.collections[coll_name.to_s]
          next unless collection
          collection.docs.each { |doc| chunks << render_doc(doc) }
        end

        if options["pages"]
          exts = Array(options["page_extensions"]).map(&:downcase)
          site.pages.each do |page|
            next unless exts.include?(File.extname(page.path).downcase)
            chunks << render_doc(page)
          end
        end

        chunks.compact.join(options["separator"] || "\n\n---\n\n") + "\n"
      end

      private

      def render_doc(doc)
        return nil if doc.data["llms_output"] == false
        return nil if doc.data["markdown_output"] == false && options["respect_markdown_output"]

        url = absolute_url(doc.url)
        title = doc.data["title"] || url
        body = source_body(doc).strip
        body = render_liquid(doc, body) if doc.data["render_with_liquid"] != false

        header = +"# #{title}\n"
        header << "\nURL: #{url}\n" if options["include_url"]
        header << "Date: #{doc.data["date"].iso8601}\n" if options["include_date"] && doc.data["date"].respond_to?(:iso8601)
        header << "\n"

        header + body
      end

      def source_path(doc)
        File.expand_path(doc.path.to_s, site.source)
      end

      def source_body(doc)
        raw = File.read(source_path(doc), encoding: "UTF-8")
        parts = raw.split(/^---\s*$\n/, 3)
        parts.length >= 3 ? parts[2] : raw
      end

      def render_liquid(doc, body)
        info = {
          filters:   [Jekyll::Filters],
          registers: { site: site, page: doc.to_liquid },
        }
        template = site.liquid_renderer.file(source_path(doc)).parse(body)
        template.render!(site.site_payload.merge("page" => doc.to_liquid), info)
      rescue StandardError => e
        rel = doc.respond_to?(:relative_path) ? doc.relative_path : doc.path
        Jekyll.logger.warn("LlmsOutput:", "render failed for #{rel}: #{e.message}")
        body
      end

      def absolute_url(url)
        site_url = site.config["url"]
        return url if url.to_s.start_with?("http")
        site_url ? "#{site_url}#{url}" : url
      end
    end
  end
end
