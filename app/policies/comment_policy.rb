# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    TicketPolicy.new(user, record.ticket).show?
  end
end
