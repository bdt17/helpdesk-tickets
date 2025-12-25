module Api
  class AiController < ApplicationController
    def status
      render json: {
        agents: 1,
        ready: true,
        test_heal: {site_id: "site-42", status: "healed"},
        test_drone: {site_id: "site-42", priority: "normal", status: "dispatched"}
      }
    end
  end
end
