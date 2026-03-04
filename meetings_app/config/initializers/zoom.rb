# config/initializers/zoom.rb
#
# Zoom API configuration
# Credentials are read from Rails credentials or ENV variables.
#
# To set via Rails credentials (recommended):
#   Run: rails credentials:edit
#   Add:
#     zoom:
#       account_id: "YOUR_ACCOUNT_ID"
#       client_id: "YOUR_CLIENT_ID"
#       client_secret: "YOUR_CLIENT_SECRET"
#
# To set via ENV variables (alternative):
#   Set ZOOM_ACCOUNT_ID, ZOOM_CLIENT_ID, ZOOM_CLIENT_SECRET
#   in your .env file or system environment.
#
# How to get credentials:
#   1. Go to https://marketplace.zoom.us/develop/create
#   2. Click "Server-to-Server OAuth"
#   3. Name your app and click Create
#   4. Go to "Scopes" tab and add:
#      - meeting:write:admin
#      - meeting:read:admin
#   5. Go to "App Credentials" tab to copy your keys
#   6. Click "Activate your app"

Rails.application.config.after_initialize do
  zoom_account_id    = Rails.application.credentials.dig(:zoom, :account_id)    || ENV["ZOOM_ACCOUNT_ID"]
  zoom_client_id     = Rails.application.credentials.dig(:zoom, :client_id)      || ENV["ZOOM_CLIENT_ID"]
  zoom_client_secret = Rails.application.credentials.dig(:zoom, :client_secret)  || ENV["ZOOM_CLIENT_SECRET"]

  if zoom_account_id.blank? || zoom_client_id.blank? || zoom_client_secret.blank?
    Rails.logger.warn <<~MSG
      ⚠️  ZOOM API CREDENTIALS NOT SET
      Zoom meeting creation will be skipped until credentials are configured.
      See config/initializers/zoom.rb for setup instructions.
    MSG
  else
    Rails.logger.info "✅ Zoom API credentials loaded successfully."
  end
end
