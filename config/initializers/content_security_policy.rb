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

  # Shipped as report-only: this sandbox has no working browser to verify
  # the policy against, so it logs violations without blocking anything
  # until someone confirms a real browser session is clean, then flips
  # this to false.
  config.content_security_policy_report_only = true
end
