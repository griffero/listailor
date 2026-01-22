require "rails_helper"

RSpec.describe "API Authentication", type: :request do
  let!(:stage) { create(:pipeline_stage) }
  let!(:application) { create(:application) }

  describe "bearer token authentication" do
    context "without token" do
      it "returns unauthorized" do
        post "/api/v1/application_events", params: {
          application_id: application.id,
          event_type: "note",
          message: "Test note"
        }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Unauthorized")
      end
    end

    context "with invalid token" do
      it "returns unauthorized" do
        post "/api/v1/application_events",
          params: { application_id: application.id, event_type: "note", message: "Test" },
          headers: { "Authorization" => "Bearer invalid-token" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid token" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("N8N_API_TOKEN").and_return("valid-token")
      end

      it "allows access" do
        post "/api/v1/application_events",
          params: { application_id: application.id, event_type: "note", message: "Test" },
          headers: { "Authorization" => "Bearer valid-token" }

        expect(response).to have_http_status(:created)
      end
    end

    context "when API token not configured" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("N8N_API_TOKEN").and_return(nil)
      end

      it "returns service unavailable" do
        post "/api/v1/application_events",
          params: { application_id: application.id, event_type: "note", message: "Test" },
          headers: { "Authorization" => "Bearer some-token" }

        expect(response).to have_http_status(:service_unavailable)
      end
    end
  end
end
