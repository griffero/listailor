Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root redirects to internal app
  root "redirect#index"

  # ============================================
  # Public Embed Routes (iframe-friendly)
  # ============================================
  scope :embed, module: :embed, as: :embed do
    get "jobs", to: "jobs#index"
    get "jobs/:slug", to: "jobs#show", as: :job
    get "jobs/:slug/apply", to: "jobs#apply", as: :job_apply
    post "jobs/:slug/apply", to: "jobs#create_application"
    get "jobs/:slug/apply/success", to: "jobs#apply_success", as: :job_apply_success
  end

  # ============================================
  # Authentication Routes
  # ============================================
  scope :auth do
    get "login", to: "auth#login", as: :login
    post "magic_link", to: "auth#send_magic_link", as: :send_magic_link
    get "magic_link/:token", to: "auth#verify_magic_link", as: :verify_magic_link
    post "logout", to: "auth#logout", as: :logout
  end

  # ============================================
  # Internal App Routes (protected by auth)
  # ============================================
  scope :app, module: :app, as: :app do
    # Dashboard
    get "/", to: "dashboard#index", as: :dashboard

    # Jobs
    resources :jobs do
      member do
        post :publish
        post :unpublish
      end
      resources :questions, only: [:create, :update, :destroy]
    end

    # Pipeline
    get "pipeline", to: "pipeline#index"
    resources :pipeline_stages, only: [:create, :update, :destroy] do
      collection do
        post :reorder
      end
    end

    # Applications
    resources :applications, only: [:index, :show, :new, :create] do
      member do
        post :move_stage
      end
      resources :notes, only: [:create], controller: "application_notes"
      resources :emails, only: [:new, :create], controller: "application_emails"
    end

    # Email Templates
    resources :email_templates

    # Settings
    get "settings", to: "settings#index"
    patch "settings", to: "settings#update"

    # Reports
    get "reports", to: "reports#index"
    get "reports/candidates_per_stage", to: "reports#candidates_per_stage"
    get "reports/time_in_stage", to: "reports#time_in_stage"

    # Search
    get "search", to: "search#index"
  end

  # ============================================
  # API Routes for n8n (bearer token auth)
  # ============================================
  namespace :api do
    namespace :v1 do
      # Application events (notes, external events)
      resources :application_events, only: [:create]

      # Email messages (upsert for inbound/outbound)
      resources :email_messages, only: [:create]

      # Interview events
      resources :interviews, only: [:create, :update]
    end
  end
end
