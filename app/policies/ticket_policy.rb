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

  # CSAT: only the person who actually filed the ticket rates it - not
  # just anyone on the same team (see owner?) - so a rating reflects one
  # requester's real experience, and only once it's done, so staff can't
  # skew the numbers and a rating can't be resubmitted to overwrite an
  # earlier one.
  def rate?
    filed_by? && record.rateable?
  end

  class Scope < Scope
    def resolve
      if user.agent? || user.admin?
        scope.all
      elsif user.organization_id.present?
        # Team billing (Phase 12): seats on the same organization share
        # visibility into each other's tickets.
        scope.where(user: User.where(organization_id: user.organization_id))
      else
        scope.where(user: user)
      end
    end
  end

  private

  def filed_by?
    record.user_id == user.id
  end

  # "Owner" here means "can see and act on this ticket as a client-side
  # participant" - either the person who actually filed it, or a teammate
  # on the same billed organization (Phase 12 made a subscription cover a
  # whole team, not just one person).
  def owner?
    filed_by? || same_org?
  end

  def same_org?
    user.organization_id.present? && record.user&.organization_id == user.organization_id
  end

  def staff?
    user.agent? || user.admin?
  end
end
