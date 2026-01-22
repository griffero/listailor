# Seed default pipeline stages
puts "Creating default pipeline stages..."

stages = [
  { name: "Applied", position: 0, kind: "active" },
  { name: "Screening", position: 1, kind: "active" },
  { name: "Interview", position: 2, kind: "active" },
  { name: "Offer", position: 3, kind: "active" },
  { name: "Hired", position: 4, kind: "hired" },
  { name: "Rejected", position: 5, kind: "rejected" }
]

stages.each do |stage_attrs|
  PipelineStage.find_or_create_by!(name: stage_attrs[:name]) do |stage|
    stage.position = stage_attrs[:position]
    stage.kind = stage_attrs[:kind]
  end
end

puts "Created #{PipelineStage.count} pipeline stages"

# Seed default email templates (in Spanish)
puts "Creating default email templates..."

templates = [
  {
    name: "Confirmación de Postulación",
    subject: "Hemos recibido tu postulación para {{job.title}}",
    body: <<~BODY
      Hola {{candidate.first_name}},

      Gracias por postularte al cargo de {{job.title}} en Fintoc.

      Hemos recibido tu información y nuestro equipo la revisará pronto. Te contactaremos en caso de avanzar en el proceso.

      Saludos,
      El equipo de Fintoc
    BODY
  },
  {
    name: "Invitación a Entrevista",
    subject: "Siguiente paso: Entrevista para {{job.title}}",
    body: <<~BODY
      Hola {{candidate.first_name}},

      ¡Buenas noticias! Nos gustaría conocerte mejor y avanzar con tu postulación al cargo de {{job.title}}.

      Te invitamos a una entrevista con nuestro equipo. Por favor, responde este correo con tu disponibilidad para las próximas semanas.

      Puedes ver el detalle de tu postulación aquí: {{application.url}}

      Saludos,
      El equipo de Fintoc
    BODY
  },
  {
    name: "Avance de Etapa",
    subject: "Actualización de tu postulación - {{job.title}}",
    body: <<~BODY
      Hola {{candidate.first_name}},

      Queremos informarte que tu postulación al cargo de {{job.title}} ha avanzado a la etapa de {{stage.name}}.

      Pronto nos pondremos en contacto contigo con los siguientes pasos.

      Saludos,
      El equipo de Fintoc
    BODY
  },
  {
    name: "Oferta de Trabajo",
    subject: "¡Oferta de trabajo para {{job.title}}!",
    body: <<~BODY
      Hola {{candidate.first_name}},

      ¡Felicitaciones! Después de un proceso de selección exitoso, nos complace extenderte una oferta formal para el cargo de {{job.title}} en Fintoc.

      Nos pondremos en contacto contigo para revisar los detalles de la oferta.

      Saludos,
      El equipo de Fintoc
    BODY
  },
  {
    name: "Rechazo",
    subject: "Actualización sobre tu postulación - {{job.title}}",
    body: <<~BODY
      Hola {{candidate.first_name}},

      Gracias por tu interés en el cargo de {{job.title}} en Fintoc y por el tiempo que invertiste en el proceso de selección.

      Después de una cuidadosa evaluación, hemos decidido continuar con otros candidatos cuyo perfil se ajusta más a lo que buscamos en este momento.

      Te animamos a postularte a futuras oportunidades que puedan ser de tu interés.

      Saludos,
      El equipo de Fintoc
    BODY
  }
]

templates.each do |template_attrs|
  EmailTemplate.find_or_create_by!(name: template_attrs[:name]) do |template|
    template.subject = template_attrs[:subject]
    template.body = template_attrs[:body].strip
  end
end

puts "Created #{EmailTemplate.count} email templates"

# Create default settings
puts "Creating default settings..."

Setting.set("embed_allowed_origins", ENV.fetch("EMBED_ALLOWED_ORIGINS", "http://localhost:3000"))

puts "Done seeding!"
