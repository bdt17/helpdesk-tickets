class Api::AiController < ApplicationController
  skip_before_action :verify_authenticity_token
  def status
    render json: {
      status: 'active',
      model: 'Claude 3.5 Sonnet',
      agents: 3
    }
  end
end
