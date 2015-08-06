require_relative '../api'

describe EmailService::API::Addresses do

  let(:emails_api) { EmailService::API::Api }

  describe "#get_sender" do
    before(:each) do
      emails_api.addresses.create(
        community_id: 123, opts: {
          name: "Email Sender Name",
          email: "hello@mymarketplace.invalid"
        })
    end

    context "user defined sender address" do

      it "gets sender address by community id" do
        res = emails_api.addresses.get_sender(community_id: 123)

        expect(res.success).to eq(true)
        expect(res.data).to eq("\"Email Sender Name\" <hello@mymarketplace.invalid>")
      end
    end

    context "default sender address" do

      it "returns default address user defined address is not set" do
        res = emails_api.addresses.get_sender(community_id: 999)

        expect(res.success).to eq(true)
        expect(res.data).to eq("Default Sender Name <default_sender@example.com.invalid>")
      end

      it "returns default address user defined address is not set" do
        res = emails_api.addresses.get_sender(community_id: nil)

        expect(res.success).to eq(true)
        expect(res.data).to eq("Default Sender Name <default_sender@example.com.invalid>")
      end
    end
  end
end
