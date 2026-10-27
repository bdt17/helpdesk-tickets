# Be sure to restart your server when you modify this file.
#
# The layout (app/views/layouts/application.html.erb) loads Bootstrap and
# Font Awesome from jsdelivr/cdnjs and has a legacy inline <style> block, so
# style-src stays permissive (:unsafe_inline) rather than trying to nonce or
# rewrite that CSS as part of a security-hardening pass. script-src does not
# get :unsafe_inline - the importmap/module scripts Rails renders are nonced
# instead, and there are no other inline <script>/onclick= handlers anywhere
# in the app (verified via a full app/views grep).
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data, "https://cdnjs.cloudflare.com"
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, "https://cdn.jsdelivr.net"
    policy.style_src   :self, :unsafe_inline, "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"
    policy.connect_src :self
    policy.base_uri    :self
  end

  # Generate session nonces for permitted importmap/inline module scripts.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Enforced since 2026-10-25, after a real browser session on production
  # (home, dashboard, tickets, new ticket, leads) reported no violations
  # under report-only. Every <script> must come from 'self'/jsdelivr or
  # carry the nonce (content_security_policy_nonce); no inline handlers.
  config.content_security_policy_report_only = false
end
