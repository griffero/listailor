module Teamtailor
  module Mappers
    class MessageMapper
      def self.upsert!(payload, application:)
        attributes = payload.fetch("attributes", {})
        teamtailor_id = payload["id"]

        record =
          if email_like?(attributes)
            upsert_email!(application, teamtailor_id, attributes)
          else
            upsert_event!(application, teamtailor_id, attributes)
          end

        synced_at = Utils.parse_time(Utils.attr(attributes, "updated_at", "updated-at", "created_at", "created-at")) || Time.current
        application.mark_teamtailor_state_synced!(synced_at: synced_at)
        record
      end

      def self.email_like?(attributes)
        return true if Utils.attr(attributes, "subject", "body", "body_html", "from", "from_address").present?

        type = Utils.attr(attributes, "type", "message_type", "kind", "communication_type")
        type.to_s.downcase.include?("email")
      end

      def self.upsert_email!(application, teamtailor_id, attributes)
        email = EmailMessage.find_or_initialize_by(teamtailor_id: teamtailor_id, application: application)
        email.direction = map_direction(Utils.attr(attributes, "direction", "type"))
        email.status = map_status(Utils.attr(attributes, "status"))
        email.from_address = Utils.attr(attributes, "from", "from_address", "sender") || email.from_address
        email.to_address = Utils.attr(attributes, "to", "to_address", "recipient") || email.to_address
        email.subject = Utils.attr(attributes, "subject", "title") || email.subject
        email.body_html = Utils.attr(attributes, "body_html", "body", "content")
        email.provider_message_id = Utils.attr(attributes, "provider_message_id", "provider-id")

        sent_at = Utils.parse_time(Utils.attr(attributes, "sent_at", "sent-at"))
        received_at = Utils.parse_time(Utils.attr(attributes, "received_at", "received-at", "created_at", "created-at"))
        email.sent_at = sent_at if sent_at.present?
        email.received_at = received_at if received_at.present?

        email.direction ||= "outbound"
        email.status ||= email.direction == "inbound" ? "received" : "sent"
        email.from_address ||= "unknown@teamtailor.invalid"
        email.to_address ||= "unknown@teamtailor.invalid"
        email.subject ||= "Teamtailor message"

        email.save!
        email
      end

      def self.upsert_event!(application, teamtailor_id, attributes)
        occurred_at = Utils.parse_time(Utils.attr(attributes, "occurred_at", "created_at", "created-at")) || Time.current
        message = Utils.attr(attributes, "title", "subject", "summary") || "Teamtailor activity"

        event = ApplicationEvent
          .where(application: application)
          .where("payload ->> 'teamtailor_id' = ?", teamtailor_id.to_s)
          .first_or_initialize

        event.event_type = "external_event"
        event.message = message
        event.occurred_at = occurred_at
        event.payload = attributes.merge("teamtailor_id" => teamtailor_id)
        event.save!
        event
      end

      def self.map_direction(value)
        normalized = value.to_s.downcase
        return "inbound" if normalized.include?("inbound") || normalized.include?("incoming") || normalized.include?("received")

        "outbound"
      end

      def self.map_status(value)
        normalized = value.to_s.downcase
        return "received" if normalized.include?("received") || normalized.include?("inbound")
        return "failed" if normalized.include?("failed")
        return "queued" if normalized.include?("queued")

        "sent"
      end
    end
  end
end
