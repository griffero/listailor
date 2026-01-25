namespace :teamtailor do
  desc "Fast backfill of applications without answers"
  task fast_backfill_applications: :environment do
    client = Teamtailor::Client.new
    service = Teamtailor::SyncService.new(client: client)
    
    before = Application.count
    puts "Starting fast application backfill (skip_answers)..."
    puts "Before: #{before} applications"
    
    ENV["TEAMTAILOR_SKIP_ANSWERS"] = "true"
    processed = service.sync("applications", full_sync: true)
    
    after = Application.count
    puts "Done. After: #{after} applications (+#{after - before})"
    puts "Processed: #{processed} items"
  end
  
  desc "Backfill answers for existing applications"
  task backfill_answers: :environment do
    client = Teamtailor::Client.new
    total = Application.count
    processed = 0
    errors = 0
    
    puts "Backfilling answers for #{total} applications..."
    
    Application.find_each(batch_size: 100) do |app|
      processed += 1
      
      begin
        # Skip if already has answers
        next if app.application_answers.where.not(job_question_id: nil).any?
        
        # Fetch and apply answers
        resp = client.get("/job-applications/#{app.teamtailor_id}", params: {"include" => "job,candidate,stage"})
        payload = resp["data"]
        included_index = Teamtailor::Utils.index_included(resp["included"])
        
        Teamtailor::Mappers::ApplicationMapper.apply_answers!(app, payload, included_index, client: client)
        
        puts "#{processed}/#{total}: App #{app.id} - #{app.application_answers.where.not(job_question_id: nil).count} answers" if processed % 50 == 0
      rescue => e
        errors += 1
        puts "ERROR on app #{app.id}: #{e.message[0..80]}"
      end
    end
    
    puts "Done. Processed: #{processed}, Errors: #{errors}"
  end
end
