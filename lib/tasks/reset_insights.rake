# frozen_string_literal: true

namespace :insights do
  desc "Reset startup experience and year tenure insights for re-extraction"
  task reset_startup_and_tenure: :environment do
    puts "Resetting startup experience and tenure insights..."
    
    # Reset both insights to null so they get re-extracted
    count = Application.where.not(processing_completed_at: nil).update_all(
      has_startup_experience: nil,
      has_year_tenure: nil,
      processing_completed_at: nil  # This will trigger re-extraction
    )
    
    puts "Reset #{count} applications. They will be re-extracted by the EducationExtractionJob."
  end
  
  desc "Reset cover letter evaluations for re-evaluation"
  task reset_cover_letters: :environment do
    puts "Resetting cover letter evaluations..."
    
    count = Application.where.not(cover_letter_decision: nil).update_all(
      cover_letter_evaluation: nil,
      cover_letter_decision: nil
    )
    
    puts "Reset #{count} cover letter evaluations."
  end
end
