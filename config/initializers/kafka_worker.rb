Rails.application.config.after_initialize do
  Thread.new { OrderProcessWorker.start }
end
