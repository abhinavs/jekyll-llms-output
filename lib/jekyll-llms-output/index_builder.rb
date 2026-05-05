# frozen_string_literal: true

module Jekyll
  module LlmsOutput
    # Builds the body of /llms.txt.
    #
    # Two modes:
    #   1. Data-driven: site.data[<key>] holds a hash with title / description /
    #      sections. The plugin renders that structure to llmstxt.org format.
    #   2. Auto: no data hash present. The plugin generates one section per
    #      configured collection with a bullet for each document.
    #
    # llmstxt.org spec we follow:
    #   # Title
    #   > Optional one-line description
    #   ## Section heading
    #   - [Title](url): optional description
    class IndexBuilder
      attr_reader :site, :options

      def initialize(site, options)
        @site = site
        @options = options
      end

      def build
        data_key = options["data"]
        data_hash = data_key && site.data[data_key.to_s]

        if data_hash.is_a?(Hash) && data_hash["sections"]
          render_from_data(data_hash)
        else
          render_auto
        end
      end

      private

      def render_from_data(data)
        out = +""
        title = data["title"] || site.config["title"]
        description = data["description"] || site.config["description"]

        out << "# #{title}\n\n" if title && !title.to_s.empty?
        if description && !description.to_s.empty?
          out << "> #{description.to_s.strip}\n\n"
        end

        Array(data["sections"]).each do |section|
          heading = section["heading"] || section["title"]
          next unless heading
          out << "## #{heading}\n\n"
          Array(section["links"]).each do |link|
            out << format_link(link["title"], link["url"], link["description"])
          end
          out << "\n"
        end

        out.strip + "\n"
      end

      def render_auto
        out = +""
        title = options["title"] || site.config["title"]
        description = options["description"] || site.config["description"]

        out << "# #{title}\n\n" if title && !title.to_s.empty?
        if description && !description.to_s.empty?
          out << "> #{description.to_s.strip}\n\n"
        end

        Array(options["collections"]).each do |coll_name|
          collection = site.collections[coll_name.to_s]
          next unless collection && !collection.docs.empty?
          out << "## #{section_heading_for(coll_name)}\n\n"
          docs_in_render_order(collection.docs).each do |doc|
            url = absolute_url(doc.url)
            out << format_link(doc.data["title"] || url, url, summary_for(doc))
          end
          out << "\n"
        end

        out.strip + "\n"
      end

      def docs_in_render_order(docs)
        # Newest first when docs have a date.
        docs.sort_by { |d| d.respond_to?(:date) && d.date ? d.date : Time.at(0) }.reverse
      end

      def section_heading_for(name)
        # "posts" -> "Posts", "design_notes" -> "Design notes"
        s = name.to_s.tr("_-", " ")
        s.empty? ? "Items" : s[0].upcase + s[1..]
      end

      def format_link(title, url, description)
        line = "- [#{title}](#{url})"
        line += ": #{description.to_s.strip}" if description && !description.to_s.empty?
        line + "\n"
      end

      def summary_for(doc)
        s = doc.data["summary"]
        return s.strip if s.is_a?(String) && !s.strip.empty?
        excerpt = doc.data["excerpt"]
        return nil if excerpt.nil?
        text = excerpt.respond_to?(:content) ? excerpt.content : excerpt
        text = text.to_s.gsub(/<[^>]+>/, "").strip
        text.empty? ? nil : text.split(/\n\n/).first.to_s.strip
      end

      def absolute_url(url)
        site_url = site.config["url"]
        return url if url.to_s.start_with?("http")
        site_url ? "#{site_url}#{url}" : url
      end
    end
  end
end
