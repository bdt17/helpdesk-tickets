class AgentsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @agents = User.where(role: "agent").order(:email)
  end
end
