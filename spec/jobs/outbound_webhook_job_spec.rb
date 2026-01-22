require "rails_helper"

RSpec.describe OutboundWebhookJob, type: :job do
  let!(:stage) { create(:pipeline_stage) }
  let!(:application) { create(:application) }

  describe "#perform" do
    context "when webhook URL is configured" do
      before do
        Setting.set("outbound_webhook_url", "https://n8n.example.com/webhook/test")
      end

      it "sends webhook with correct payload" do
        stub = stub_request(:post, "https://n8n.example.com/webhook/test")
          .with(
            body: hash_including(
              "event" => "application.created",
              "data" => hash_including(
                "application_id" => application.id
              )
            ),
            headers: { "Content-Type" => "application/json" }
          )
          .to_return(status: 200, body: "{}")

        described_class.perform_now(application.id)

        expect(stub).to have_been_requested
      end

      it "raises error on failed delivery for retry" do
        stub_request(:post, "https://n8n.example.com/webhook/test")
          .to_return(status: 500, body: "Internal Server Error")

        expect {
          described_class.perform_now(application.id)
        }.to raise_error(/Webhook delivery failed/)
      end
    end

    context "when webhook URL is not configured" do
      before do
        Setting.where(key: "outbound_webhook_url").destroy_all
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OUTBOUND_WEBHOOK_URL").and_return(nil)
      end

      it "does not send webhook" do
        expect(HTTParty).not_to receive(:post)
        described_class.perform_now(application.id)
      end
    end
  end

  describe "retry configuration" do
    it "is configured with exponential backoff" do
      expect(described_class.retry_on_configurations).to include(
        have_attributes(
          wait: :polynomially_longer,
          attempts: 10
        )
      )
    end
  end
end
