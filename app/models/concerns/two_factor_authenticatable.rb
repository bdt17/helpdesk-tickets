# Authenticator-app (TOTP) two-factor login, required for staff (agents
# and admins) because one phished staff password otherwise exposes every
# client's tickets. Clients don't use it (yet).
#
# - otp_secret is encrypted at rest (see config/initializers/active_record_encryption.rb).
# - otp_last_used_step stops the same 6-digit code being used twice.
# - Backup codes are stored only as HMAC digests and each works once.
module TwoFactorAuthenticatable
  extend ActiveSupport::Concern

  OTP_ISSUER = "Thomas IT Helpdesk".freeze
  OTP_INTERVAL = 30
  # Accept the previous/next 30-second code too, for phone clock drift.
  OTP_DRIFT = 30
  BACKUP_CODE_COUNT = 10

  included do
    encrypts :otp_secret
    serialize :otp_backup_code_digests, coder: JSON, type: Array
  end

  class_methods do
    def generate_otp_secret
      ROTP::Base32.random
    end

    def backup_code_digest(code)
      key = Rails.application.key_generator.generate_key("two_factor/backup_codes", 32)
      OpenSSL::HMAC.hexdigest("SHA256", key, normalize_backup_code(code))
    end

    def normalize_backup_code(code)
      code.to_s.downcase.gsub(/[^a-z0-9]/, "")
    end
  end

  def two_factor_enabled?
    otp_enabled_at.present? && otp_secret.present?
  end

  def two_factor_required?
    staff?
  end

  def otp_provisioning_uri(secret)
    ROTP::TOTP.new(secret, issuer: OTP_ISSUER).provisioning_uri(email)
  end

  # Turns 2FA on once the person proves their app has `secret` by typing a
  # current code. Returns the plain backup codes (shown once) or nil.
  def enable_two_factor!(secret, code)
    step = matching_otp_step(secret, code, after_step: nil)
    return nil unless step

    codes = new_backup_codes
    update!(otp_secret: secret, otp_enabled_at: Time.current, otp_last_used_step: step,
            otp_backup_code_digests: codes.map { |c| self.class.backup_code_digest(c) })
    codes
  end

  # A 6-digit authenticator code or an unused backup code. Each code is
  # accepted at most once. Returns :otp, :backup_code or nil.
  def verify_second_factor!(code)
    return nil unless two_factor_enabled?

    with_lock do
      if (step = matching_otp_step(otp_secret, code, after_step: otp_last_used_step))
        update!(otp_last_used_step: step)
        :otp
      elsif consume_backup_code(code)
        save!
        :backup_code
      end
    end
  end

  # Set by TwoFactorSessionsController once the code is right.
  attr_accessor :second_factor_passed

  # Devise resets failed_attempts as soon as a password is right. For 2FA
  # accounts that would let someone with the password re-enter it every
  # 4 wrong codes and never get locked out, so only a full sign-in
  # (password + code) resets the count.
  def reset_failed_attempts!
    return false if two_factor_enabled? && !second_factor_passed

    super
  end

  # A wrong code counts like a wrong password for Devise's lockable.
  # Returns true if this failure locked the account.
  def register_failed_second_factor!
    increment_failed_attempts
    return false unless attempts_exceeded?

    lock_access!
    true
  end

  def backup_codes_remaining
    Array(otp_backup_code_digests).size
  end

  def regenerate_backup_codes!
    codes = new_backup_codes
    update!(otp_backup_code_digests: codes.map { |c| self.class.backup_code_digest(c) })
    codes
  end

  # Admin reset for a lost phone. Staff are asked to set 2FA up again on
  # their next sign-in.
  def reset_two_factor!
    update!(otp_secret: nil, otp_enabled_at: nil, otp_last_used_step: nil, otp_backup_code_digests: nil)
  end

  private

  def matching_otp_step(secret, code, after_step:)
    code = code.to_s.gsub(/\s/, "")
    return nil unless secret.present? && code.match?(/\A\d{6}\z/)

    after = after_step && after_step * OTP_INTERVAL
    timestamp = ROTP::TOTP.new(secret).verify(code, drift_behind: OTP_DRIFT, drift_ahead: OTP_DRIFT, after: after)
    timestamp && timestamp / OTP_INTERVAL
  end

  def consume_backup_code(code)
    return false if self.class.normalize_backup_code(code).length != 10

    digests = Array(otp_backup_code_digests)
    digest = self.class.backup_code_digest(code)
    match = digests.find { |d| ActiveSupport::SecurityUtils.secure_compare(d, digest) }
    return false unless match

    self.otp_backup_code_digests = digests - [ match ]
    true
  end

  def new_backup_codes
    Array.new(BACKUP_CODE_COUNT) do
      raw = SecureRandom.hex(5)
      "#{raw[0, 5]}-#{raw[5, 5]}"
    end
  end
end
