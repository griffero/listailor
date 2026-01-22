# Listailor ATS

A minimal internal Applicant Tracking System (ATS) built with Rails 8, PostgreSQL, TailwindCSS, and Vue 3.

## Features

- **Magic Link Authentication** - No passwords, just email-based login
- **Job Postings** - Create and manage job listings with custom questions
- **Embeddable Jobs Widget** - iframe-friendly pages for embedding in external sites
- **Pipeline Management** - Kanban board with drag-and-drop stage management
- **Email Thread** - Compose and track emails per application
- **Timeline** - Full history of application events, stage changes, and communications
- **n8n Integration** - Webhook-based automation with API endpoints for external systems
- **Basic Reporting** - Candidates per stage per week, average time in stage

## Tech Stack

- **Backend**: Rails 8, PostgreSQL, Solid Queue (background jobs)
- **Frontend**: Vue 3 + Inertia.js, TailwindCSS
- **File Storage**: ActiveStorage (local or S3-compatible)

## Local Development

### Prerequisites

- Ruby 3.2+
- Node.js 18+
- PostgreSQL 14+
- Bundler

### Setup

```bash
# Clone the repository
git clone <repo-url>
cd listailor

# Install dependencies
bundle install
npm install

# Setup database
rails db:create db:migrate db:seed

# Start the development server
bin/dev
```

The app will be available at `http://localhost:3000`.

### Development Commands

```bash
# Run Rails server only
rails server

# Run Vite dev server only
npm run dev

# Run both (recommended)
bin/dev

# Run background jobs
bin/jobs

# Run tests
bundle exec rspec

# Run Tailwind build
rails tailwindcss:build
```

## Environment Variables

### Required for Production

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgres://user:pass@host/db` |
| `SECRET_KEY_BASE` | Rails secret key | Auto-generated |
| `RAILS_MASTER_KEY` | Rails credentials key | From `config/master.key` |
| `APP_HOST` | Full URL of the application | `https://ats.fintoc.com` |

### Email Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `SMTP_ADDRESS` | SMTP server address | `smtp.sendgrid.net` |
| `SMTP_PORT` | SMTP server port | `587` |
| `SMTP_USERNAME` | SMTP username | `apikey` |
| `SMTP_PASSWORD` | SMTP password/API key | `SG.xxxxx` |
| `SMTP_FROM_ADDRESS` | Sender email address | `noreply@fintoc.com` |

### n8n Integration

| Variable | Description | Example |
|----------|-------------|---------|
| `OUTBOUND_WEBHOOK_URL` | Webhook URL for new applications | `https://n8n.example.com/webhook/...` |
| `N8N_SEND_EMAIL_WEBHOOK_URL` | Webhook URL for sending emails | `https://n8n.example.com/webhook/...` |
| `N8N_API_TOKEN` | Bearer token for API authentication | `your-secure-token` |

### Embed Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `EMBED_ALLOWED_ORIGINS` | Comma-separated list of allowed iframe origins | `https://fintoc.com,https://www.fintoc.com` |

## Embedding the Jobs Widget

### Basic iframe embed

```html
<iframe 
  src="https://your-ats-domain.com/embed/jobs" 
  width="100%" 
  height="600" 
  frameborder="0"
></iframe>
```

### With UTM tracking

```html
<iframe 
  src="https://your-ats-domain.com/embed/jobs?utm_source=website&utm_campaign=careers" 
  width="100%" 
  height="600" 
  frameborder="0"
></iframe>
```

### Auto-resize (optional)

```html
<iframe 
  id="jobs-iframe"
  src="https://your-ats-domain.com/embed/jobs" 
  width="100%" 
  frameborder="0"
></iframe>

<script>
  window.addEventListener('message', function(e) {
    if (e.data.type === 'resize') {
      document.getElementById('jobs-iframe').style.height = e.data.height + 'px';
    }
  });
</script>
```

### Available embed routes

- `/embed/jobs` - List all published jobs
- `/embed/jobs/:slug` - Job detail page
- `/embed/jobs/:slug/apply` - Application form

## API Documentation

All API endpoints require bearer token authentication:

```
Authorization: Bearer YOUR_N8N_API_TOKEN
```

### Create Application Event

```bash
POST /api/v1/application_events

{
  "application_id": 123,
  "event_type": "external_event",
  "message": "Candidate responded via email",
  "payload": { "source": "gmail" },
  "occurred_at": "2026-01-22T10:00:00Z"
}
```

### Upsert Email Message

```bash
POST /api/v1/email_messages

{
  "application_id": 123,
  "direction": "inbound",
  "status": "received",
  "from_address": "candidate@example.com",
  "to_address": "hr@fintoc.com",
  "subject": "Re: Interview Schedule",
  "body_html": "<p>Thank you for the invitation...</p>",
  "provider_message_id": "msg-123",
  "received_at": "2026-01-22T10:00:00Z"
}
```

### Create Interview Event

```bash
POST /api/v1/interviews

{
  "application_id": 123,
  "title": "Technical Interview",
  "scheduled_at": "2026-01-25T14:00:00Z",
  "duration_minutes": 60,
  "meeting_url": "https://meet.google.com/xxx",
  "participants": ["interviewer@fintoc.com", "candidate@example.com"]
}
```

## Webhook Payload

When a new application is submitted, a webhook is sent to `OUTBOUND_WEBHOOK_URL`:

```json
{
  "event": "application.created",
  "timestamp": "2026-01-22T10:30:00Z",
  "data": {
    "application_id": 123,
    "application_url": "https://ats.fintoc.com/app/applications/123",
    "job": {
      "id": 45,
      "title": "Senior Software Engineer",
      "slug": "senior-software-engineer",
      "department": "Engineering",
      "location": "Remote"
    },
    "candidate": {
      "id": 67,
      "first_name": "Juan",
      "last_name": "Pérez",
      "email": "juan@example.com",
      "phone": "+56912345678",
      "linkedin_url": "https://linkedin.com/in/juanperez"
    },
    "source": "linkedin",
    "utm": {
      "source": "linkedin",
      "medium": "social",
      "campaign": "hiring-2026"
    },
    "answers": [
      {
        "question_id": 1,
        "question": "Why do you want to work at Fintoc?",
        "answer": "I'm passionate about fintech..."
      }
    ],
    "cv_url": "https://ats.fintoc.com/rails/active_storage/blobs/...",
    "stage": {
      "id": 1,
      "name": "Applied"
    },
    "created_at": "2026-01-22T10:30:00Z"
  }
}
```

## Deployment to Render

### Using Blueprint

1. Fork/clone this repository
2. Create a new Render account or login
3. Click "New" → "Blueprint"
4. Connect your repository
5. Render will auto-detect `render.yaml` and create the services
6. Configure environment variables marked as `sync: false`:
   - `RAILS_MASTER_KEY`
   - `APP_HOST`
   - SMTP settings
   - n8n webhook URLs (optional)

### Manual Deployment

1. Create a PostgreSQL database
2. Create a web service:
   - Build: `bundle install && npm install && rails assets:precompile && rails db:migrate`
   - Start: `bundle exec puma -C config/puma.rb`
3. Create a background worker:
   - Build: `bundle install`
   - Start: `bundle exec rake solid_queue:start`
4. Set all environment variables

## Creating Your First User

After deployment, create a user via Rails console:

```bash
rails console

User.create!(email: "your-email@fintoc.com")
```

Then request a magic link via the login page.

## Default Pipeline Stages

The seed data creates these default stages:

1. Applied (active)
2. Screening (active)
3. Interview (active)
4. Offer (active)
5. Hired (terminal)
6. Rejected (terminal)

You can customize stages in the Pipeline section of the internal app.

## License

Private - Fintoc
