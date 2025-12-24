class AiAutopilot
  def heal_device(device_id, issue)
    agents = AiAgent.where("content ILIKE ?", "%#{issue}%")
    { device_id: device_id, agents_found: agents.count, issue: issue }
  end
  
  def dispatch_drone(site_id, priority: "normal")
    { site_id: site_id, priority: priority, status: "dispatched" }
  end
end
