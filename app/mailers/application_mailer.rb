class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("SMTP_FROM_ADDRESS", "noreply@listailor.local") }
  layout "mailer"
end
