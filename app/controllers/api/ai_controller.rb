class Api::AiController < ApplicationController
  def status
    render json: {
      agents: AiAgent.count,
      ready: true,
      test_heal: AiAutopilot.new.heal_device("switch-123", "EOL"),
      test_drone: AiAutopilot.new.dispatch_drone("site-42")
    }
  end
end
