class FixLegacyIntegerRoleValues < ActiveRecord::Migration[8.1]
  # AddRoleToUsers (20260128013707) set every pre-existing user's role to
  # the integer 1 ("All users = agent", per its own comment).
  # ConvertUsersRoleToString later cast that integer column to a string via
  # role::text - which produces the literal string "1", not "agent".
  # AddRoleConstraintsToUsers only backfilled NULL/blank roles, not "1", so
  # every user account that existed before today's migrations ended up
  # with role = "1" - not a valid value for the employee/agent/admin enum.
  #
  # Confirmed the actual production symptom this caused: Rails' enum
  # silently returns nil for an unmapped raw value (it doesn't raise), but
  # the layout's navbar calls current_user.role.humanize on every page,
  # and .humanize on nil raises NoMethodError - a 500 on every page, for
  # every pre-existing user, the instant they're signed in. Reproduced
  # and confirmed locally before writing this fix.
  #
  # "1" -> "agent" matches both AddRoleToUsers's own stated intent and how
  # this app's User#agent? always behaved before today (hardcoded to
  # return true for any authenticated user) - existing accounts keep the
  # access level they already had, nothing is downgraded. "0"/"2" are
  # handled defensively in case anything ever wrote the old customer/admin
  # integer values from the long-abandoned enum sketch in
  # app/models/user.rb.bak2; any other non-enum value falls back to
  # employee, same precedent as AddRoleConstraintsToUsers's NULL/blank
  # handling.
  LEGACY_ROLE_MAP = { "0" => "employee", "1" => "agent", "2" => "admin" }.freeze
  VALID_ROLES = %w[employee agent admin].freeze

  def up
    LEGACY_ROLE_MAP.each do |old_value, new_value|
      execute "UPDATE users SET role = #{quote(new_value)} WHERE role = #{quote(old_value)}"
    end
    execute "UPDATE users SET role = #{quote('employee')} WHERE role NOT IN (#{VALID_ROLES.map { |r| quote(r) }.join(', ')})"
  end

  def down
    # Not meaningfully reversible - the original integer semantics are gone.
  end
end
