# frozen_string_literal: true

# Minimal policy establishing the admin-only account-management pattern.
# There is no admin UI wired up to it yet (Phase 1 keeps provisioning
# CLI/rake-based) but future controllers should authorize through this.
class UserPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  class Scope < Scope
    def resolve
      user.admin? ? scope.all : scope.none
    end
  end
end
