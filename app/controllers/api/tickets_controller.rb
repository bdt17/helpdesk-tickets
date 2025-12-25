module Api
  class TicketsController < ApplicationController
    def index
      render json: [{id: 1, status: 'open', priority: 'high'}]
    end
    def create; render json: {status: 'created'}; end
    def show; render json: {id: params[:id], status: 'resolved'}; end
  end
end
