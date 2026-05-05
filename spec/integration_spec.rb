# frozen_string_literal: true

RSpec.describe "Jekyll site build with jekyll-llms-output" do
  context "auto mode (no _data/llms.yml)" do
    let(:built) { build_site }
    let(:dest) { built[1] }
    after { FileUtils.rm_rf(dest) }

    it "writes /llms.txt" do
      expect(dest.join("llms.txt")).to exist
      body = read_dest(dest, "llms.txt")
      expect(body).to start_with("# Fixture Site")
      expect(body).to include("> A test site for jekyll-llms-output.")
      expect(body).to include("## Posts")
      expect(body).to include("Hello World")
      expect(body).to include("Second Post")
    end

    it "skips opted-out posts in /llms-full.txt" do
      body = read_dest(dest, "llms-full.txt")
      expect(body).not_to include("Should not appear")
    end

    it "writes /llms-full.txt with bodies" do
      expect(dest.join("llms-full.txt")).to exist
      body = read_dest(dest, "llms-full.txt")
      expect(body).to include("# Hello World")
      expect(body).to include("This is the body of the post.")
      expect(body).to include("# Second Post")
    end

    it "renders Liquid in full output bodies by default" do
      body = read_dest(dest, "llms-full.txt")
      expect(body).to include("Site URL is https://example.com.")
      expect(body).not_to include("Site URL is {{ site.url }}.")
    end
  end

  context "with a curated _data/llms.yml" do
    around do |example|
      data_dir = File.join(FIXTURE_SITE, "_data")
      FileUtils.mkdir_p(data_dir)
      File.write(File.join(data_dir, "llms.yml"), <<~YAML)
        title: My Curated Title
        description: Curated description.
        sections:
          - heading: Featured
            links:
              - title: Hand-picked
                url: https://example.com/hand-picked
                description: Curated link.
      YAML
      example.run
    ensure
      FileUtils.rm_f(File.join(FIXTURE_SITE, "_data", "llms.yml"))
    end

    it "uses the curated structure for /llms.txt" do
      _, dest = build_site
      body = read_dest(dest, "llms.txt")
      expect(body).to include("# My Curated Title")
      expect(body).to include("> Curated description.")
      expect(body).to include("## Featured")
      expect(body).to include("- [Hand-picked](https://example.com/hand-picked): Curated link.")
      # Should not have auto sections.
      expect(body).not_to include("## Posts")
    ensure
      FileUtils.rm_rf(dest) if dest
    end
  end

  context "configuration overrides" do
    it "respects enabled: false (writes neither file)" do
      _, dest = build_site("llms_output" => { "enabled" => false })
      expect(dest.join("llms.txt")).not_to exist
      expect(dest.join("llms-full.txt")).not_to exist
    ensure
      FileUtils.rm_rf(dest) if dest
    end

    it "respects index.enabled: false" do
      _, dest = build_site("llms_output" => { "index" => { "enabled" => false } })
      expect(dest.join("llms.txt")).not_to exist
      expect(dest.join("llms-full.txt")).to exist
    ensure
      FileUtils.rm_rf(dest) if dest
    end

    it "respects full.enabled: false" do
      _, dest = build_site("llms_output" => { "full" => { "enabled" => false } })
      expect(dest.join("llms.txt")).to exist
      expect(dest.join("llms-full.txt")).not_to exist
    ensure
      FileUtils.rm_rf(dest) if dest
    end

    it "writes to a custom output path" do
      _, dest = build_site("llms_output" => {
        "index" => { "output" => "/agents/index.txt" },
        "full" => { "output" => "/agents/full.txt" },
      })
      expect(dest.join("agents/index.txt")).to exist
      expect(dest.join("agents/full.txt")).to exist
    ensure
      FileUtils.rm_rf(dest) if dest
    end
  end
end
