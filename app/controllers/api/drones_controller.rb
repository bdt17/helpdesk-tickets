module Api
  class DronesController < ApplicationController
    def index
      render json: [{id: 1, status: 'active', site: 'site-42'}]
    end
    
    def status
      render json: {drones: 3, ready: 2, dispatched: 1}
    end
  end
end
