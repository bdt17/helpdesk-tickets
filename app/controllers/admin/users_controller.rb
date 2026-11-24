# Admin-only account management, so roles and access no longer need the
# Render Shell (bin/user-admin / rails runner). Admins can add staff,
# change a staff member's role, and disable or re-enable any account -
# Devise checks User#active_for_authentication? on every request, so a
# disabled user is signed out on their next click.
#
# Client accounts belong to an Organization and get their access from its
# subscription, so their role isn't editable here (turning a client into
# staff would leave a staff account attached to a paying org).
module Admin
  class UsersController < ApplicationController
    STAFF_ROLES = %w[employee agent admin].freeze

    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_user, only: :update

    def index
      @role = params[:role].presence_in(User.roles.keys)
      @query = params[:q].to_s.strip
      users = User.includes(:organization).order(:email)
      users = users.where(role: @role) if @role
      users = users.where("email LIKE ?", "%#{User.sanitize_sql_like(@query.downcase)}%") if @query.present?
      @users = users.limit(200)
      @counts = User.group(:role).count
    end

    def create
      email = params[:email].to_s.strip.downcase
      role = params[:role].presence_in(STAFF_ROLES)
      return redirect_to admin_users_path, alert: "Pick a role." unless role
      return redirect_to admin_users_path, alert: "That email already has an account." if User.exists?(email: email)

      # Random password nobody knows; the new staff member sets their own
      # from the invite email (same approach as TeamController#create).
      temp_password = SecureRandom.hex(16)
      user = User.new(email: email, role: role, password: temp_password, password_confirmation: temp_password)
      if user.save
        user.send_staff_invite(current_user)
        redirect_to admin_users_path, notice: "Added #{email} as #{role}. They'll get an email to set their password."
      else
        redirect_to admin_users_path, alert: user.errors.full_messages.to_sentence
      end
    end

    def update
      return reset_two_factor if params[:reset_two_factor].present?

      attrs = {}
      attrs[:role] = params[:role] if params[:role].present?
      attrs[:status] = params[:status] if params[:status].present?

      if (problem = refusal_for(attrs))
        return redirect_to admin_users_path, alert: problem
      end

      @user.update!(attrs)
      redirect_to admin_users_path, notice: "Updated #{@user.email}."
    end

    private

    # Lost phone and no backup codes left. They set 2FA up again on their
    # next sign-in - so check it's really them (call them) before resetting.
    def reset_two_factor
      return redirect_to admin_users_path, alert: "You can't reset your own two-factor here - use a backup code, or ask another admin." if @user == current_user
      return redirect_to admin_users_path, alert: "#{@user.email} doesn't have two-factor on." unless @user.two_factor_enabled?

      @user.reset_two_factor!
      redirect_to admin_users_path, notice: "Reset two-factor for #{@user.email}. They'll set it up again next time they sign in."
    end

    def set_user
      @user = User.find(params[:id])
    end

    def refusal_for(attrs)
      if attrs[:role]
        return "Unknown role." unless STAFF_ROLES.include?(attrs[:role])
        return "Client accounts' roles can't be changed here." if @user.client?
      end
      return "Unknown status." if attrs[:status] && !User.statuses.key?(attrs[:status])
      return "Nothing to change." if attrs.empty?

      # The acting admin always stays an active admin this way, so there's
      # never a way to lock everyone out.
      removing_own_access = @user == current_user &&
        ((attrs[:role] && attrs[:role] != "admin") || attrs[:status] == "disabled")
      "You can't remove your own admin access." if removing_own_access
    end
  end
end
