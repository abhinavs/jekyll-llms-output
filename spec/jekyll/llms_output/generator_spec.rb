# frozen_string_literal: true

RSpec.describe Jekyll::LlmsOutput do
  describe ".config_for" do
    it "returns deep-merged defaults when no llms_output key is set" do
      site = instance_double(Jekyll::Site, config: {})
      config = described_class.config_for(site)
      expect(config["enabled"]).to eq(true)
      expect(config["index"]["enabled"]).to eq(true)
      expect(config["index"]["output"]).to eq("/llms.txt")
      expect(config["full"]["enabled"]).to eq(true)
      expect(config["full"]["separator"]).to eq("\n\n---\n\n")
    end

    it "deep-merges user overrides into nested hashes" do
      site = instance_double(Jekyll::Site, config: {
        "llms_output" => {
          "full" => { "include_url" => false },
        },
      })
      config = described_class.config_for(site)
      expect(config["full"]["include_url"]).to eq(false)
      # Non-overridden nested keys keep defaults.
      expect(config["full"]["include_date"]).to eq(true)
      expect(config["full"]["output"]).to eq("/llms-full.txt")
    end

    it "lets users disable a single output without disabling the other" do
      site = instance_double(Jekyll::Site, config: {
        "llms_output" => { "full" => { "enabled" => false } },
      })
      config = described_class.config_for(site)
      expect(config["index"]["enabled"]).to eq(true)
      expect(config["full"]["enabled"]).to eq(false)
    end
  end
end
