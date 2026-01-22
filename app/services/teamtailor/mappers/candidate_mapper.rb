module Teamtailor
  module Mappers
    class CandidateMapper
      def self.upsert!(payload)
        attributes = payload.fetch("attributes", {})
        teamtailor_id = payload["id"]
        candidate = Candidate.find_or_initialize_by(teamtailor_id: teamtailor_id)

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
        candidate.email = Utils.attr(attributes, "email", "email-address") || candidate.email
        candidate.phone = Utils.attr(attributes, "phone", "phone-number") || candidate.phone
        candidate.linkedin_url = Utils.attr(attributes, "linkedin", "linkedin_url", "linkedin-url") || candidate.linkedin_url

        candidate.first_name ||= "Unknown"
        candidate.last_name ||= "Candidate"
        candidate.email ||= "unknown-#{teamtailor_id}@teamtailor.invalid"

        candidate.save!
        candidate
      end
    end
  end
end
