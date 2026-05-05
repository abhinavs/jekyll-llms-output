# frozen_string_literal: true

RSpec.describe Jekyll::LlmsOutput::FullBuilder do
  let(:tmpsrc) { Dir.mktmpdir("jlt-src-") }
  after { FileUtils.rm_rf(tmpsrc) }

  let(:default_options) do
    {
      "collections"     => ["posts"],
      "pages"           => false,
      "page_extensions" => [".md"],
      "separator"       => "\n\n---\n\n",
      "include_url"     => true,
      "include_date"    => true,
    }
  end

  def write_source(rel_path, body)
    abs = File.join(tmpsrc, rel_path)
    FileUtils.mkdir_p(File.dirname(abs))
    File.write(abs, body)
    abs
  end

  def make_doc(url:, data: {}, source_body: "", source_rel:)
    abs = write_source(source_rel, source_body)
    merged = { "render_with_liquid" => false }.merge(data)
    d = instance_double("Jekyll::Document", url: url, data: merged, path: abs)
    allow(d).to receive(:to_liquid).and_return({})
    allow(d).to receive(:relative_path).and_return(source_rel)
    d
  end

  def site_double(collections: {}, config: {})
    instance_double(Jekyll::Site,
                    source: tmpsrc,
                    config: { "url" => "https://example.com" }.merge(config),
                    collections: collections,
                    pages: [])
  end

  it "concatenates source bodies with a separator" do
    docs = [
      make_doc(url: "/a", data: { "title" => "A" }, source_body: "---\ntitle: A\n---\n\nBody A.",
               source_rel: "_posts/2024-01-01-a.md"),
      make_doc(url: "/b", data: { "title" => "B" }, source_body: "---\ntitle: B\n---\n\nBody B.",
               source_rel: "_posts/2024-02-02-b.md"),
    ]
    collection = instance_double(Jekyll::Collection, docs: docs)
    site = site_double(collections: { "posts" => collection })
    out = described_class.new(site, default_options).build
    expect(out).to include("Body A.")
    expect(out).to include("Body B.")
    expect(out).to include("\n---\n")
  end

  it "writes a # Title header for each document" do
    docs = [make_doc(url: "/a", data: { "title" => "Hello World" }, source_body: "Body.",
                     source_rel: "_posts/2024-01-01-a.md")]
    collection = instance_double(Jekyll::Collection, docs: docs)
    site = site_double(collections: { "posts" => collection })
    out = described_class.new(site, default_options).build
    expect(out).to include("# Hello World")
  end

  it "includes URL and Date metadata when configured" do
    docs = [make_doc(
      url: "/a",
      data: { "title" => "A", "date" => Time.utc(2024, 1, 1, 9) },
      source_body: "Body.",
      source_rel: "_posts/2024-01-01-a.md",
    )]
    collection = instance_double(Jekyll::Collection, docs: docs)
    site = site_double(collections: { "posts" => collection })
    out = described_class.new(site, default_options).build
    expect(out).to include("URL: https://example.com/a")
    expect(out).to include("Date: 2024-01-01T09:00:00")
  end

  it "omits URL/Date when toggled off" do
    docs = [make_doc(
      url: "/a",
      data: { "title" => "A", "date" => Time.utc(2024, 1, 1) },
      source_body: "Body.",
      source_rel: "_posts/2024-01-01-a.md",
    )]
    collection = instance_double(Jekyll::Collection, docs: docs)
    site = site_double(collections: { "posts" => collection })
    out = described_class.new(site, default_options.merge("include_url" => false, "include_date" => false)).build
    expect(out).not_to include("URL:")
    expect(out).not_to include("Date:")
  end

  it "honors per-doc llms_output: false" do
    docs = [
      make_doc(url: "/a", data: { "title" => "A" }, source_body: "Visible.", source_rel: "_posts/2024-01-01-a.md"),
      make_doc(url: "/b", data: { "title" => "B", "llms_output" => false }, source_body: "Hidden.",
               source_rel: "_posts/2024-02-02-b.md"),
    ]
    collection = instance_double(Jekyll::Collection, docs: docs)
    site = site_double(collections: { "posts" => collection })
    out = described_class.new(site, default_options).build
    expect(out).to include("Visible.")
    expect(out).not_to include("Hidden.")
  end

  it "honors markdown_output: false when respect_markdown_output is set" do
    docs = [
      make_doc(url: "/a", data: { "title" => "A" }, source_body: "Visible.", source_rel: "_posts/2024-01-01-a.md"),
      make_doc(url: "/b", data: { "title" => "B", "markdown_output" => false }, source_body: "Hidden.",
               source_rel: "_posts/2024-02-02-b.md"),
    ]
    collection = instance_double(Jekyll::Collection, docs: docs)
    site = site_double(collections: { "posts" => collection })
    out = described_class.new(site, default_options.merge("respect_markdown_output" => true)).build
    expect(out).to include("Visible.")
    expect(out).not_to include("Hidden.")
  end

  it "ignores frontmatter from the source body" do
    docs = [make_doc(
      url: "/a",
      data: { "title" => "A" },
      source_body: "---\ntitle: A\nsecret: hidden\n---\n\nOnly body shown.",
      source_rel: "_posts/2024-01-01-a.md",
    )]
    collection = instance_double(Jekyll::Collection, docs: docs)
    site = site_double(collections: { "posts" => collection })
    out = described_class.new(site, default_options).build
    expect(out).to include("Only body shown.")
    expect(out).not_to include("secret: hidden")
  end
end
