module Api
  class TicketsController < ApplicationController
    def index
      render json: [{id: 1, title: 'Test ticket', status: 'open'}]
    end
  end
end
