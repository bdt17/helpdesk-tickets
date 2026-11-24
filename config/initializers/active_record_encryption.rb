# Active Record encryption keys (used for User#otp_secret, the staff 2FA
# seed). The credentials file isn't a safe place for them - the old
# master.key is in public git history - so they come from env vars when
# set, and otherwise are derived from SECRET_KEY_BASE, which Render
# already keeps secret.
#
# Changing SECRET_KEY_BASE (without setting these three env vars to the
# old derived values first) makes existing 2FA secrets unreadable: every
# staff member would need their 2FA reset at /admin/users and set it up
# again. Nothing else is encrypted with these keys.
Rails.application.config.after_initialize do
  derive = lambda do |purpose|
    Rails.application.key_generator.generate_key("active_record_encryption/#{purpose}", 32).unpack1("H*")
  end

  ActiveRecord::Encryption.configure(
    primary_key: ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY") { derive.call("primary_key") },
    deterministic_key: ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY") { derive.call("deterministic_key") },
    key_derivation_salt: ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT") { derive.call("key_derivation_salt") }
  )
end
