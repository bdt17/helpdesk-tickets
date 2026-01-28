
class Api::TicketsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
    render json: [{id: 1, title: "Pharma Transport"}]
  end
end
