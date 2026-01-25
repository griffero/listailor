schedule_path = Rails.root.join("config/recurring.yml")

if schedule_path.exist?
  ENV["SOLID_QUEUE_RECURRING_SCHEDULE"] = schedule_path.to_s
end
