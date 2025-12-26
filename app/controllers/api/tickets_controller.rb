class Api::TicketsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
    render json: [
      {id: 1, title: "Pfizer site-42 HIGH", priority: "HIGH"},
      {id: 2, title: "FDA CRITICAL", priority: "URGENT"}
    ]
  end
end
