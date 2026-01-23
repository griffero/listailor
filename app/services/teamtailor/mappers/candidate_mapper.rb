module Teamtailor
  module Mappers
    class CandidateMapper
      def self.upsert!(payload)
        attributes = payload.fetch("attributes", {})
        teamtailor_id = payload["id"]
        email = Utils.attr(attributes, "email", "email-address")

        candidate = Candidate.find_by(teamtailor_id: teamtailor_id)
        if candidate.blank? && email.present?
          candidate = Candidate.find_by(email: email)
          if candidate&.teamtailor_id.present? && candidate.teamtailor_id != teamtailor_id
            Rails.logger.warn(
              "Teamtailor candidate email #{email} already linked to #{candidate.teamtailor_id}, skipping id #{teamtailor_id}"
            )
            return candidate
          end
        end

        candidate ||= Candidate.new
        candidate.teamtailor_id ||= teamtailor_id

        first_name = Utils.attr(attributes, "first_name", "first-name", "given-name")
        last_name = Utils.attr(attributes, "last_name", "last-name", "family-name")
        full_name = Utils.attr(attributes, "name", "full_name", "full-name")

        if full_name.present? && (first_name.blank? || last_name.blank?)
          name_parts = full_name.split(" ")
          first_name = name_parts.first
          last_name = name_parts[1..].join(" ").presence
        end

        candidate.first_name = first_name if first_name.present?
        candidate.last_name = last_name if last_name.present?
        if email.present?
          email_conflict = Candidate.where(email: email).where.not(id: candidate.id).exists?
          if email_conflict
            Rails.logger.warn("Teamtailor candidate email conflict for #{email}; keeping existing email")
          else
            candidate.email = email
          end
        end
        candidate.phone = Utils.attr(attributes, "phone", "phone-number") || candidate.phone
        candidate.linkedin_url = Utils.attr(attributes, "linkedin", "linkedin_url", "linkedin-url") || candidate.linkedin_url

        candidate.first_name ||= "Unknown"
        candidate.last_name ||= "Candidate"
        candidate.email ||= "unknown-#{teamtailor_id}@teamtailor.invalid"

        begin
          candidate.save!
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.warn(
            "Teamtailor candidate #{teamtailor_id} skipped: #{e.message}"
          )
        end
        candidate
      end
    end
  end
end
