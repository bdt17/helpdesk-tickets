import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Subscribes to the same "ticket_updates" broadcast that
// EscalationAlertJob and TicketCategorizationJob already send server-side
// (see app/jobs) and surfaces it as a dismissible banner. Attach to any
// element with data-controller="ticket-updates"; staff pages get it via the
// layout so escalations are visible without a page reload.
export default class extends Controller {
  static targets = ["list"]

  connect() {
    this.subscription = consumer.subscriptions.create("TicketUpdatesChannel", {
      received: (data) => this.render(data),
    })
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  render(data) {
    const banner = document.createElement("div")
    banner.className = "alert alert-warning alert-dismissible fade show shadow-sm"
    banner.setAttribute("role", "alert")

    const link = document.createElement("a")
    link.href = `/tickets/${data.ticket_id}`
    link.textContent = data.message
    link.className = "alert-link"
    banner.appendChild(link)

    const closeButton = document.createElement("button")
    closeButton.type = "button"
    closeButton.className = "btn-close"
    closeButton.setAttribute("data-bs-dismiss", "alert")
    banner.appendChild(closeButton)

    this.listTarget.prepend(banner)
  }
}
