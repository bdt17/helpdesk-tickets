#!/bin/bash
cd ~/rails_projects/helpdesk_tickets

echo "🔧 FINALIZING TECH HELPDESK - 30 seconds to complete..."

# CLEANUP
pkill -f "rails s" 2>/dev/null || true
rm -f db/migrate/*status* db/migrate/*knowledge* 2>/dev/null || true

# KNOWLEDGE BASE (fixed)
rails g model knowledge_base title:string content:text category:string device_type:string --force >/dev/null 2>&1
rails db:migrate

# LOAD DEVICE TEMPLATES
rails runner "
KnowledgeBase.delete_all
[
  {title:'Cisco ISR Swap', content:'show run | redirect tftp://192.168.1.100/backup.conf\ncopy tftp://192.168.1.100/new.conf run\nwr\nreload', device_type:'Cisco ISR'},
  {title:'FortiGate Swap', content:'execute backup config tftp 192.168.1.100/backup.conf\nexecute restore config tftp 192.168.1.100/new.conf\nget system status', device_type:'FortiGate'},
  {title:'Catalyst Reset', content:'enable\nerase startup-config\ndelete vlan.dat\nreload\nconf t\nhostname NEW-SW\nend\nwr', device_type:'Catalyst'},
  {title:'Palo Alto PA220', content:'set deviceconfig system hostname PA220\nset network interface ethernet eth1/1 layer3 ip 1.1.1.2/24\ncommit', device_type:'Palo Alto'},
  {title:'Ubiquiti UDM', content:'configure\nset system host-name UDM-PROD\nset interfaces ethernet eth0 192.168.1.2/24\ncommit ; save', device_type:'Ubiquiti'}
].each{|d| KnowledgeBase.create!(d) }
puts "✅ NETWORK TEMPLATES LOADED"
"

# PRODUCTION LAYOUT
cat > app/views/layouts/application.html.erb << 'LAYOUT'
<!DOCTYPE html>
<html><head>
<title>Tech Helpdesk</title>
<meta name="viewport" content="width=device-width">
<%= csrf_meta_tag %>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
</head><body class="bg-light">
<nav class="navbar navbar-dark bg-primary">
<div class="container">
<a class="navbar-brand fw-bold" href="/"><i class="bi bi-laptop-network"></i> Techdesk</a>
<a href="/" class="nav-link text-white me-3"><i class="bi bi-ticket"></i> Tickets</a>
<a href="/knowledge_bases" class="nav-link text-white"><i class="bi bi-book"></i> Guides</a>
</div></nav>
<main class="container mt-4">
<% if notice %><div class="alert alert-success"><%= notice %></div><% end %>
<%= yield %></main>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3/dist/js/bootstrap.bundle.min.js"></script>
</body></html>
LAYOUT

# GUIDES CONTROLLER
cat > app/controllers/knowledge_bases_controller.rb << 'EOF'
class KnowledgeBasesController < ApplicationController
  def index; @articles = KnowledgeBase.all.order(:title); end
end
