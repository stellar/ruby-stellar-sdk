RSpec.describe Stellar::Account do
  describe ".lookup" do
    it "calls Federation service" do
      expect(Stellar::Federation).to receive(:lookup).with("some_address")
      described_class.lookup("some_address")
    end
  end
end
