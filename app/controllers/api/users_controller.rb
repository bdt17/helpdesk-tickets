
module Api
  class UsersController < ApplicationController
    def index
      render json: [
        {id: 1, name: "Thomas Helpdesk Admin", role: "admin", sites: 42},
        {id: 2, name: "Pfizer Site Manager", role: "manager"}
      ]
    end
  end
end
