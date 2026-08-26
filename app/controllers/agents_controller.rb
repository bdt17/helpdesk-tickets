class AgentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_staff!

  def index
    @agents = User.agent.order(:email)
  end
end
