require "rails_helper"

RSpec.describe "Embed Applications", type: :request do
  let!(:stage) { create(:pipeline_stage, name: "Applied", position: 0) }
  let!(:job) { create(:job_posting, :published) }
  let(:cv_file) { fixture_file_upload("test_cv.pdf", "application/pdf") }

  describe "POST /embed/jobs/:slug/apply" do
    let(:valid_params) do
      {
        application: {
          first_name: "Juan",
          last_name: "Pérez",
          email: "juan@example.com",
          phone: "+56912345678",
          linkedin_url: "https://linkedin.com/in/juanperez",
          source: "linkedin",
          cv: cv_file
        }
      }
    end

    context "with valid params" do
      it "creates a new application" do
        expect {
          post embed_job_apply_path(job.slug), params: valid_params
        }.to change(Application, :count).by(1)

        expect(response).to redirect_to(embed_job_apply_success_path(job.slug))
      end

      it "creates a new candidate" do
        expect {
          post embed_job_apply_path(job.slug), params: valid_params
        }.to change(Candidate, :count).by(1)

        candidate = Candidate.last
        expect(candidate.email).to eq("juan@example.com")
        expect(candidate.first_name).to eq("Juan")
      end

      it "sets the initial stage" do
        post embed_job_apply_path(job.slug), params: valid_params

        application = Application.last
        expect(application.current_stage).to eq(stage)
      end

      it "enqueues the webhook job" do
        expect {
          post embed_job_apply_path(job.slug), params: valid_params
        }.to have_enqueued_job(OutboundWebhookJob)
      end

      it "creates a stage transition" do
        post embed_job_apply_path(job.slug), params: valid_params

        application = Application.last
        expect(application.stage_transitions.count).to eq(1)
        expect(application.stage_transitions.first.to_stage).to eq(stage)
      end
    end

    context "candidate deduplication" do
      let!(:existing_candidate) { create(:candidate, email: "JUAN@EXAMPLE.COM", first_name: "Existing", last_name: "User") }

      it "reuses existing candidate by email (case-insensitive)" do
        expect {
          post embed_job_apply_path(job.slug), params: valid_params
        }.not_to change(Candidate, :count)

        application = Application.last
        expect(application.candidate).to eq(existing_candidate)
      end

      it "updates candidate info with new data" do
        post embed_job_apply_path(job.slug), params: valid_params

        existing_candidate.reload
        expect(existing_candidate.first_name).to eq("Juan")
        expect(existing_candidate.last_name).to eq("Pérez")
      end
    end

    context "duplicate application" do
      let!(:existing_candidate) { create(:candidate, email: "juan@example.com") }
      let!(:existing_application) { create(:application, job_posting: job, candidate: existing_candidate) }

      it "does not create duplicate application for same job" do
        expect {
          post embed_job_apply_path(job.slug), params: valid_params
        }.not_to change(Application, :count)

        expect(flash[:alert]).to include("Ya has postulado")
      end
    end

    context "with UTM params" do
      it "stores UTM parameters" do
        params_with_utm = valid_params.deep_merge(
          application: {
            utm_source: "google",
            utm_medium: "cpc",
            utm_campaign: "hiring-2026"
          }
        )

        post embed_job_apply_path(job.slug), params: params_with_utm

        application = Application.last
        expect(application.utm_source).to eq("google")
        expect(application.utm_medium).to eq("cpc")
        expect(application.utm_campaign).to eq("hiring-2026")
      end
    end
  end

  describe "GET /embed/jobs" do
    let!(:published_job) { create(:job_posting, :published) }
    let!(:draft_job) { create(:job_posting, :draft) }

    it "only shows published jobs" do
      get embed_jobs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(published_job.title)
      expect(response.body).not_to include(draft_job.title)
    end

    it "sets iframe-friendly headers" do
      get embed_jobs_path

      expect(response.headers["Content-Security-Policy"]).to include("frame-ancestors")
    end
  end
end
