module App
  class SearchController < BaseController
    def index
      query = params[:q]

      if query.blank?
        render inertia: "App/Search/Index", props: {
          query: "",
          candidates: [],
          applications: [],
          jobs: []
        }
        return
      end

      candidates = Candidate.search(query).limit(20)
      applications = Application.search(query).includes(:candidate, :job_posting, :current_stage).limit(20)
      jobs = JobPosting.where("title ILIKE ?", "%#{query}%").limit(20)

      render inertia: "App/Search/Index", props: {
        query: query,
        candidates: candidates.map { |c| serialize_candidate(c) },
        applications: applications.map { |a| serialize_application(a) },
        jobs: jobs.map { |j| serialize_job(j) }
      }
    end

    private

    def serialize_candidate(candidate)
      {
        id: candidate.id,
        name: candidate.full_name,
        email: candidate.email,
        applicationsCount: candidate.applications.count
      }
    end

    def serialize_application(app)
      {
        id: app.id,
        candidate: { id: app.candidate.id, name: app.candidate.full_name, email: app.candidate.email },
        job: { id: app.job_posting.id, title: app.job_posting.title },
        stage: app.current_stage ? { name: app.current_stage.name } : nil,
        createdAt: app.created_at.iso8601
      }
    end

    def serialize_job(job)
      {
        id: job.id,
        title: job.title,
        department: job.department,
        published: job.published?
      }
    end
  end
end
