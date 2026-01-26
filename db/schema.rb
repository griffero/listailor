# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_26_184105) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "application_answers", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.bigint "job_question_id"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "global_question_id"
    t.index ["application_id"], name: "index_application_answers_on_application_id"
    t.index ["global_question_id"], name: "index_application_answers_on_global_question_id"
    t.index ["job_question_id"], name: "index_application_answers_on_job_question_id"
  end

  create_table "application_events", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.bigint "created_by_user_id"
    t.string "event_type", null: false
    t.text "message"
    t.jsonb "payload", default: {}
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "occurred_at"], name: "index_application_events_on_application_id_and_occurred_at"
    t.index ["application_id"], name: "index_application_events_on_application_id"
    t.index ["created_by_user_id"], name: "index_application_events_on_created_by_user_id"
  end

  create_table "application_stage_transitions", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.bigint "from_stage_id"
    t.bigint "to_stage_id", null: false
    t.datetime "transitioned_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id", "transitioned_at"], name: "idx_app_stage_transitions_on_app_and_time"
    t.index ["application_id"], name: "index_application_stage_transitions_on_application_id"
    t.index ["from_stage_id"], name: "index_application_stage_transitions_on_from_stage_id"
    t.index ["to_stage_id"], name: "index_application_stage_transitions_on_to_stage_id"
  end

  create_table "applications", force: :cascade do |t|
    t.bigint "job_posting_id", null: false
    t.bigint "candidate_id", null: false
    t.bigint "current_stage_id"
    t.string "source"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_campaign"
    t.string "utm_term"
    t.string "utm_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "teamtailor_id"
    t.datetime "teamtailor_state_synced_at"
    t.datetime "teamtailor_full_sync_at"
    t.jsonb "education"
    t.datetime "processing_completed_at"
    t.index ["candidate_id"], name: "index_applications_on_candidate_id"
    t.index ["current_stage_id"], name: "index_applications_on_current_stage_id"
    t.index ["job_posting_id", "candidate_id"], name: "index_applications_on_job_posting_id_and_candidate_id", unique: true
    t.index ["job_posting_id"], name: "index_applications_on_job_posting_id"
    t.index ["processing_completed_at"], name: "index_applications_on_processing_completed_at"
    t.index ["teamtailor_full_sync_at"], name: "index_applications_on_teamtailor_full_sync_at"
    t.index ["teamtailor_id"], name: "index_applications_on_teamtailor_id", unique: true
    t.index ["teamtailor_state_synced_at"], name: "index_applications_on_teamtailor_state_synced_at"
  end

  create_table "candidates", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "linkedin_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "teamtailor_id"
    t.index "lower((email)::text)", name: "index_candidates_on_lower_email", unique: true
    t.index ["teamtailor_id"], name: "index_candidates_on_teamtailor_id", unique: true
  end

  create_table "email_messages", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.string "direction"
    t.string "status"
    t.string "from_address"
    t.string "to_address"
    t.string "subject"
    t.text "body_html"
    t.string "provider_message_id"
    t.datetime "sent_at"
    t.datetime "received_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "teamtailor_id"
    t.index ["application_id"], name: "index_email_messages_on_application_id"
    t.index ["teamtailor_id"], name: "index_email_messages_on_teamtailor_id", unique: true
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "subject", null: false
    t.text "body", null: false
    t.bigint "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_email_templates_on_created_by_user_id"
    t.index ["name"], name: "index_email_templates_on_name", unique: true
  end

  create_table "global_questions", force: :cascade do |t|
    t.string "kind"
    t.string "label"
    t.boolean "required", default: false
    t.integer "position"
    t.jsonb "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "interview_events", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "scheduled_at"
    t.integer "duration_minutes"
    t.string "title"
    t.string "meeting_url"
    t.jsonb "participants"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_interview_events_on_application_id"
  end

  create_table "job_postings", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "description"
    t.string "department"
    t.string "location"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "archived_at"
    t.string "teamtailor_id"
    t.index ["archived_at"], name: "index_job_postings_on_archived_at"
    t.index ["slug"], name: "index_job_postings_on_slug", unique: true
    t.index ["teamtailor_id"], name: "index_job_postings_on_teamtailor_id", unique: true
  end

  create_table "job_questions", force: :cascade do |t|
    t.bigint "job_posting_id", null: false
    t.string "kind"
    t.string "label"
    t.boolean "required"
    t.integer "position"
    t.jsonb "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "teamtailor_id"
    t.index ["job_posting_id", "teamtailor_id"], name: "index_job_questions_on_job_posting_id_and_teamtailor_id", unique: true
    t.index ["job_posting_id"], name: "index_job_questions_on_job_posting_id"
  end

  create_table "pipeline_stages", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "kind", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "teamtailor_id"
    t.bigint "job_posting_id"
    t.string "canonical_stage"
    t.index ["canonical_stage"], name: "index_pipeline_stages_on_canonical_stage"
    t.index ["job_posting_id", "teamtailor_id"], name: "index_pipeline_stages_on_job_and_tt_id", unique: true, where: "(teamtailor_id IS NOT NULL)"
    t.index ["job_posting_id"], name: "index_pipeline_stages_on_job_posting_id"
    t.index ["kind"], name: "index_pipeline_stages_on_kind"
    t.index ["position"], name: "index_pipeline_stages_on_position"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "teamtailor_sync_locks", force: :cascade do |t|
    t.string "key", null: false
    t.string "locked_by"
    t.datetime "locked_at"
    t.datetime "heartbeat_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_teamtailor_sync_locks_on_key", unique: true
  end

  create_table "teamtailor_sync_states", force: :cascade do |t|
    t.string "resource", null: false
    t.string "cursor"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource"], name: "index_teamtailor_sync_states_on_resource", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "magic_login_token"
    t.datetime "magic_login_sent_at"
    t.datetime "last_signed_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "application_answers", "applications"
  add_foreign_key "application_answers", "global_questions"
  add_foreign_key "application_answers", "job_questions"
  add_foreign_key "application_events", "applications"
  add_foreign_key "application_events", "users", column: "created_by_user_id"
  add_foreign_key "application_stage_transitions", "applications"
  add_foreign_key "application_stage_transitions", "pipeline_stages", column: "from_stage_id"
  add_foreign_key "application_stage_transitions", "pipeline_stages", column: "to_stage_id"
  add_foreign_key "applications", "candidates"
  add_foreign_key "applications", "job_postings"
  add_foreign_key "applications", "pipeline_stages", column: "current_stage_id"
  add_foreign_key "email_messages", "applications"
  add_foreign_key "email_templates", "users", column: "created_by_user_id"
  add_foreign_key "interview_events", "applications"
  add_foreign_key "job_questions", "job_postings"
  add_foreign_key "pipeline_stages", "job_postings"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
