class Api::DronesController < ApplicationController
  def index
    render json: [
      {id:1,status:"active",site:"site-42",battery:87},
      {id:2,status:"charging",site:"site-17"}
    ]
  end
end
