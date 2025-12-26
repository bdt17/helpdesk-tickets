class Api::DronesController < ApplicationController
  def index
    render json: [
      {id:1,model:"DJI Mavic 3",status:"active",location:"Phoenix AZ",battery:87},
      {id:2,model:"DJI Air 3",status:"charging",location:"Las Vegas NV",battery:23}
    ]
  end
end
