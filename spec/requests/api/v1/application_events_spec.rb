require "rails_helper"

RSpec.describe "API Application Events", type: :request do
  let!(:stage) { create(:pipeline_stage) }
  let!(:application) { create(:application) }
  let(:headers) { { "Authorization" => "Bearer valid-token" } }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("N8N_API_TOKEN").and_return("valid-token")
  end

  describe "POST /api/v1/application_events" do
    it "creates a timeline event" do
      expect {
        post "/api/v1/application_events",
          params: {
            application_id: application.id,
            event_type: "external_event",
            message: "Candidate responded to email",
            payload: { source: "gmail" }
          },
          headers: headers
      }.to change(ApplicationEvent, :count).by(1)

      expect(response).to have_http_status(:created)

      event = ApplicationEvent.last
      expect(event.event_type).to eq("external_event")
      expect(event.message).to eq("Candidate responded to email")
    end

    it "returns 404 for non-existent application" do
      post "/api/v1/application_events",
        params: { application_id: 99999, event_type: "note", message: "Test" },
        headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
