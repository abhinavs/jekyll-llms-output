# frozen_string_literal: true

RSpec.describe Jekyll::LlmsOutput::IndexBuilder do
  let(:default_options) do
    {
      "data"        => "llms",
      "collections" => ["posts"],
    }
  end

  def site_double(config: {}, data: {}, collections: {})
    instance_double(Jekyll::Site, config: config, data: data, collections: collections)
  end

  def doc(url:, data: {}, date: nil)
    d = instance_double("Jekyll::Document", url: url, data: data, date: date)
    d
  end

  describe "data-driven mode" do
    it "renders title, description, and sections from a data hash" do
      site = site_double(
        config: { "title" => "Site", "description" => "Site desc" },
        data: {
          "llms" => {
            "title" => "Custom Title",
            "description" => "Custom desc",
            "sections" => [
              {
                "heading" => "Featured",
                "links" => [
                  { "title" => "Terminal Second Life", "url" => "/terminal-second-life", "description" => "Agentic tooling" },
                  { "title" => "Speed",                "url" => "/speed" },
                ],
              },
              {
                "heading" => "Optional",
                "links"   => [{ "title" => "Blog", "url" => "/blog" }],
              },
            ],
          },
        },
      )
      out = described_class.new(site, default_options).build
      expect(out).to include("# Custom Title")
      expect(out).to include("> Custom desc")
      expect(out).to include("## Featured")
      expect(out).to include("- [Terminal Second Life](/terminal-second-life): Agentic tooling")
      expect(out).to include("- [Speed](/speed)\n")
      expect(out).to include("## Optional")
      expect(out).to include("- [Blog](/blog)")
    end

    it "falls back to site title and description when data omits them" do
      site = site_double(
        config: { "title" => "Site Title", "description" => "Site Desc" },
        data: {
          "llms" => {
            "sections" => [{ "heading" => "S", "links" => [{ "title" => "x", "url" => "/x" }] }],
          },
        },
      )
      out = described_class.new(site, default_options).build
      expect(out).to start_with("# Site Title")
      expect(out).to include("> Site Desc")
    end

    it "supports 'title' as an alias for 'heading'" do
      site = site_double(data: {
        "llms" => { "sections" => [{ "title" => "Posts", "links" => [{ "title" => "x", "url" => "/x" }] }] },
      })
      out = described_class.new(site, default_options).build
      expect(out).to include("## Posts")
    end

    it "skips sections without a heading" do
      site = site_double(data: {
        "llms" => {
          "sections" => [
            { "links" => [{ "title" => "ghost", "url" => "/ghost" }] },
            { "heading" => "Real", "links" => [{ "title" => "x", "url" => "/x" }] },
          ],
        },
      })
      out = described_class.new(site, default_options).build
      expect(out).not_to include("ghost")
      expect(out).to include("## Real")
    end
  end

  describe "auto mode" do
    it "generates one section per non-empty collection" do
      posts = [
        doc(url: "/p1", data: { "title" => "Post 1", "summary" => "First." }, date: Time.utc(2024, 1, 1)),
        doc(url: "/p2", data: { "title" => "Post 2" },                       date: Time.utc(2024, 2, 1)),
      ]
      collection = instance_double(Jekyll::Collection, docs: posts)
      site = site_double(
        config: { "title" => "T", "description" => "D", "url" => "https://example.com" },
        data: {},
        collections: { "posts" => collection },
      )
      out = described_class.new(site, default_options).build
      expect(out).to include("# T")
      expect(out).to include("## Posts")
      # Newest first.
      expect(out.index("Post 2")).to be < out.index("Post 1")
      # Absolute URLs.
      expect(out).to include("https://example.com/p1")
    end

    it "skips collections that have no docs" do
      empty = instance_double(Jekyll::Collection, docs: [])
      site = site_double(
        config: { "title" => "T" },
        data: {},
        collections: { "posts" => empty },
      )
      out = described_class.new(site, default_options).build
      expect(out).not_to include("##")
    end

    it "uses summary, then excerpt, as the link description" do
      excerpt = double(content: "<p>Excerpted.</p>")
      docs = [
        doc(url: "/a", data: { "title" => "A", "summary" => "Set." }),
        doc(url: "/b", data: { "title" => "B", "excerpt" => excerpt }),
      ]
      collection = instance_double(Jekyll::Collection, docs: docs)
      site = site_double(
        config: { "url" => "https://x.test" },
        data: {},
        collections: { "posts" => collection },
      )
      out = described_class.new(site, default_options).build
      expect(out).to include("- [A](https://x.test/a): Set.")
      expect(out).to include("- [B](https://x.test/b): Excerpted.")
    end

    it "humanizes underscored collection names" do
      docs = [doc(url: "/n1", data: { "title" => "N" })]
      collection = instance_double(Jekyll::Collection, docs: docs)
      site = site_double(
        config: {},
        data: {},
        collections: { "design_notes" => collection },
      )
      out = described_class.new(site, default_options.merge("collections" => ["design_notes"])).build
      expect(out).to include("## Design notes")
    end
  end
end
