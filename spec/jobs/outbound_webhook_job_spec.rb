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

      it "retries job on failed delivery" do
        stub_request(:post, "https://n8n.example.com/webhook/test")
          .to_return(status: 500, body: "Internal Server Error")

        # With retry_on, the job will catch the error and re-enqueue
        # We test that the job is enqueued for retry
        expect {
          described_class.perform_now(application.id)
        }.to have_enqueued_job(described_class).with(application.id)
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
    it "is configured to retry on errors" do
      # Verify the job has retry_on handler set up by checking behavior
      # When a StandardError is raised, the job should be re-enqueued
      Setting.set("outbound_webhook_url", "https://n8n.example.com/webhook/test")
      stub_request(:post, "https://n8n.example.com/webhook/test")
        .to_return(status: 500, body: "Error")

      expect {
        described_class.perform_now(application.id)
      }.to have_enqueued_job(described_class)
    end
  end
end
