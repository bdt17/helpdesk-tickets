class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end

# Simple role check (add role column to users later if needed)
def client_user?
  current_user.role == 'client' || !current_user.tech? # Customize
end
