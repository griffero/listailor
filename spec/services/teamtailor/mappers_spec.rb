require "rails_helper"

RSpec.describe Teamtailor::Mappers do
  describe Teamtailor::Mappers::JobPostingMapper do
    it "upserts a job posting from payload" do
      payload = {
        "id" => "job-123",
        "attributes" => {
          "title" => "Backend Engineer",
          "description" => "Build APIs",
          "department" => "Engineering",
          "location" => "Remote",
          "published-at" => "2026-01-01T12:00:00Z"
        }
      }

      job = described_class.upsert!(payload)

      expect(job.teamtailor_id).to eq("job-123")
      expect(job.title).to eq("Backend Engineer")
      expect(job.description).to eq("Build APIs")
      expect(job.department).to eq("Engineering")
      expect(job.location).to eq("Remote")
      expect(job.published_at).to be_present
    end
  end

  describe Teamtailor::Mappers::CandidateMapper do
    it "upserts a candidate from payload" do
      payload = {
        "id" => "cand-123",
        "attributes" => {
          "first-name" => "Ana",
          "last-name" => "Perez",
          "email" => "ana@example.com"
        }
      }

      candidate = described_class.upsert!(payload)

      expect(candidate.teamtailor_id).to eq("cand-123")
      expect(candidate.first_name).to eq("Ana")
      expect(candidate.last_name).to eq("Perez")
      expect(candidate.email).to eq("ana@example.com")
    end
  end

  describe Teamtailor::Mappers::ApplicationMapper do
    it "creates an application with answers and cover letter" do
      job = JobPosting.create!(
        teamtailor_id: "job-1",
        title: "Engineer",
        description: "Role description"
      )
      candidate = Candidate.create!(
        teamtailor_id: "cand-1",
        first_name: "Jo",
        last_name: "Doe",
        email: "jo@example.com"
      )

      payload = {
        "id" => "app-1",
        "attributes" => {
          "cover-letter" => "I want this job",
          "created-at" => "2026-01-02T10:00:00Z"
        },
        "relationships" => {
          "job" => { "data" => { "type" => "jobs", "id" => "job-1" } },
          "candidate" => { "data" => { "type" => "candidates", "id" => "cand-1" } },
          "answers" => { "data" => [{ "type" => "answers", "id" => "ans-1" }] }
        }
      }

      included_index = Teamtailor::Utils.index_included([
        {
          "id" => "ans-1",
          "type" => "answers",
          "attributes" => { "value" => "Because I care" },
          "relationships" => { "question" => { "data" => { "type" => "questions", "id" => "q-1" } } }
        },
        {
          "id" => "q-1",
          "type" => "questions",
          "attributes" => { "label" => "Why us?", "type" => "long_text", "required" => true }
        }
      ])

      application = described_class.upsert!(payload, included_index: included_index)

      expect(application.teamtailor_id).to eq("app-1")
      expect(application.job_posting).to eq(job)
      expect(application.candidate).to eq(candidate)

      cover_letter_question = GlobalQuestion.find_by(label: "Cover Letter (Teamtailor)")
      expect(cover_letter_question).to be_present
      expect(ApplicationAnswer.find_by(application: application, global_question: cover_letter_question)).to be_present

      job_question = JobQuestion.find_by(teamtailor_id: "q-1")
      expect(job_question).to be_present
      expect(ApplicationAnswer.find_by(application: application, job_question: job_question)).to be_present
    end
  end
end
