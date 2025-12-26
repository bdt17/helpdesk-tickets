class TechController < ApplicationController
  def dashboard
    render inline: <<-HTML
    <!DOCTYPE html>
    <html><body>
      <h1>Thomas IT Helpdesk 🚀</h1>
      <button onclick="fetch('/api/health').then(r=>r.json()).then(d=>alert('Health: '+d.status))">Health</button>
      <button onclick="fetch('/api/tickets').then(r=>r.json()).then(d=>alert('Tickets: '+d.length))">Tickets</button>
      <button onclick="fetch('/api/drones').then(r=>r.json()).then(d=>alert('Drones: '+d.length))">Drones</button>
      <button onclick="fetch('/api/ai_status').then(r=>r.json()).then(d=>alert('AI: '+d.status))">AI Status</button>
    </body></html>
    HTML
  end
end
