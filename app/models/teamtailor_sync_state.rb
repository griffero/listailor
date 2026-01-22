class TeamtailorSyncState < ApplicationRecord
  validates :resource, presence: true, uniqueness: true

  def self.fetch(resource)
    find_or_create_by!(resource: resource)
  end
end
