class HomeController < ApplicationController
  before_action :authenticate_user!, only: :dashboard

  def index
    @message = "Thomas IT Helpdesk"
  end

  def dashboard
    @message = "Agent Dashboard Ready"
  end
end
