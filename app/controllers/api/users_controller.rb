module Api
  class UsersController < ApplicationController
    def index
      render json: [{id: 1, name: 'Thomas Helpdesk Admin', role: 'admin'}]
    end
  end
end
