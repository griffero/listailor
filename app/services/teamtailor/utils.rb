module Teamtailor
  module Utils
    def self.attr(attributes, *keys)
      return nil unless attributes.is_a?(Hash)

      keys.each do |key|
        key_str = key.to_s
        value = attributes[key_str]
        return value if value.present?

        dashed_key = key_str.tr("_", "-")
        value = attributes[dashed_key]
        return value if value.present?
      end

      nil
    end

    def self.parse_time(value)
      return nil if value.blank?
      return value if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def self.index_included(included)
      return {} unless included.is_a?(Array)

      included.each_with_object({}) do |item, index|
        type = item["type"]
        id = item["id"]
        next if type.blank? || id.blank?

        index["#{type}:#{id}"] = item
      end
    end

    def self.find_included(index, type, id)
      return nil if index.blank? || type.blank? || id.blank?

      index["#{type}:#{id}"]
    end
  end
end
