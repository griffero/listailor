class TeamtailorSyncLock < ApplicationRecord
  validates :key, presence: true, uniqueness: true
end
