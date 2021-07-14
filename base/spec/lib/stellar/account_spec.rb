RSpec.describe Stellar::Account do
  describe ".random" do
    it "generates a Stellar account with a random keypair" do
      account = described_class.random
      expect(account.address).to match account.keypair.address
    end
  end

  describe ".from_seed" do
    let(:random_account) { described_class.random }
    subject(:account) do
      described_class.from_seed(random_account.keypair.seed)
    end

    it "generates an account from a seed" do
      expect(account.keypair.seed).to eq random_account.keypair.seed
    end
  end

  describe ".random" do
    it "generates a Stellar account with a random keypair" do
      account = described_class.random
      expect(account.keypair).to be_a Stellar::KeyPair
    end
  end

  describe ".from_address" do
    subject { described_class.from_address(address) }

    context "when G-address is provided" do
      let(:address) { "GAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSTVY" }

      its("id") { is_expected.to be_nil }
      its("keypair.address") { is_expected.to eq(address) }
    end

    context "when M-address is provided" do
      let(:address) { "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK" }
      let(:xdr_account) { Stellar::MuxedAccount.from_xdr("\x00\x00\x01\x00\x80\x00\x00\x00\x00\x00\x00\x00\x3f\x0c\x34\xbf\x93\xad\x0d\x99\x71\xd0\x4c\xcc\x90\xf7\x05\x51\x1c\x83\x8a\xad\x97\x34\xa4\xa2\xfb\x0d\x7a\x03\xfc\x7f\xe8\x9a") }

      its("id") { is_expected.to eq(9223372036854775808) }
      its("keypair.raw_public_key") { is_expected.to eq(xdr_account.med25519.ed25519) }
    end
  end

  describe "#to_muxed" do
    let(:keypair) { Stellar::KeyPair.random }
    let(:id) { 15 }
    subject { described_class.new(keypair, id).to_muxed }

    it { is_expected.to be_a(Stellar::MuxedAccount) }
    its("switch.name") { is_expected.to eq("key_type_muxed_ed25519") }
    its("med25519.id") { is_expected.to eq(id) }
    its("med25519.ed25519") { is_expected.to eq(keypair.raw_public_key) }

    context "when id is not set" do
      subject { described_class.new(keypair).to_muxed }

      its("med25519.id") { is_expected.to be_nil }
    end
  end

  describe "#to_ed25519" do
    let(:keypair) { Stellar::KeyPair.random }
    let(:id) { 15 }
    subject { described_class.new(keypair, id).to_ed25519 }

    it { is_expected.to be_a(Stellar::MuxedAccount) }
    its("switch.name") { is_expected.to eq("key_type_ed25519") }
    its("ed25519") { is_expected.to eq(keypair.raw_public_key) }
  end

  describe "#address" do
    let(:m_address) { "MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAE2LP26" }
    subject do
      described_class
        .from_address(m_address)
        .address(force_account_id: force_account_id)
    end

    context "when 'G-' format is forced" do
      let(:force_account_id) { true }

      it { is_expected.to eq("GAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSTVY") }
    end

    context "when 'M-' format is forced" do
      let(:force_account_id) { false }

      it { is_expected.to eq(m_address) }
    end
  end
end
