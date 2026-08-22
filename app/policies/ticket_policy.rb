# frozen_string_literal: true

class TicketPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    owner? || staff?
  end

  def create?
    true
  end

  def update?
    owner? || staff?
  end

  def destroy?
    user.admin?
  end

  class Scope < Scope
    def resolve
      if user.agent? || user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end

  private

  def owner?
    record.user_id == user.id
  end

  def staff?
    user.agent? || user.admin?
  end
end
