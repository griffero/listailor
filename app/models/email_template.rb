class EmailTemplate < ApplicationRecord
  belongs_to :created_by_user, class_name: "User", optional: true

  validates :name, presence: true, uniqueness: true
  validates :subject, presence: true
  validates :body, presence: true

  scope :ordered, -> { order(name: :asc) }

  # Available variables for templates
  VARIABLES = %w[
    candidate.first_name
    candidate.last_name
    candidate.email
    job.title
    job.department
    job.location
    application.url
    stage.name
  ].freeze

  def render_subject(context)
    TemplateRenderer.render(subject, context)
  end

  def render_body(context)
    TemplateRenderer.render(body, context)
  end
end
