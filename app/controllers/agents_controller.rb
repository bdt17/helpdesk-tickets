class AgentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @agents = User.agent.order(:email)
  end
end
