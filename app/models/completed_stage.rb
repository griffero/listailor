# frozen_string_literal: true

class CompletedStage < ApplicationRecord
  belongs_to :application
  belongs_to :pipeline_stage

  validates :application_id, uniqueness: { scope: :pipeline_stage_id }
end
