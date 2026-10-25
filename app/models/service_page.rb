# The public "what we do" pages at /services/:slug - one per service, so
# search engines have a page to rank for each thing a prospect searches
# for ("small business network support", "computer repair for business")
# instead of a single homepage. Same in-code registry shape as Plan.
#
# SERVICE_AREA (e.g. "Phoenix, AZ") is optional: when set, it's worked
# into page titles and descriptions ("... in Phoenix, AZ"), which is what
# local "near me" searches match on. Copy stays general otherwise - the
# help desk isn't tied to one location.
class ServicePage
  Definition = Struct.new(:slug, :name, :icon, :headline, :summary, :includes, keyword_init: true)

  ALL = [
    Definition.new(
      slug: "managed-it-help-desk", name: "Managed IT Help Desk", icon: "fa-headset",
      headline: "An IT help desk for your business, without hiring an IT team",
      summary: "Your staff open a ticket, a real technician picks it up, and you get response times written into your plan.",
      includes: [
        "Ticket tracking so nothing gets lost in an inbox",
        "Response-time commitments by priority, escalated when missed",
        "One place for your whole team to ask for help",
        "A monthly summary of what we fixed for you"
      ]
    ),
    Definition.new(
      slug: "network-support", name: "Network & Wi-Fi Support", icon: "fa-network-wired",
      headline: "Network and Wi-Fi support for small businesses",
      summary: "Slow Wi-Fi, dropped connections, VPN trouble and outages diagnosed and fixed, plus equipment upgrades planned for you.",
      includes: [
        "Troubleshooting connectivity, Wi-Fi and outages",
        "Router, switch and access point setup",
        "VPN and remote access for staff",
        "Planning network upgrades and equipment swaps"
      ]
    ),
    Definition.new(
      slug: "computer-repair", name: "Computer & Hardware Support", icon: "fa-desktop",
      headline: "Computer and hardware support for your team",
      summary: "Workstations, laptops, printers and peripherals set up, repaired and kept running so your staff can work.",
      includes: [
        "New computer setup and migration",
        "Diagnosing slow, crashing or failing machines",
        "Printers, monitors and peripherals",
        "Repair and replacement recommendations"
      ]
    ),
    Definition.new(
      slug: "software-support", name: "Software & Cloud App Support", icon: "fa-laptop-code",
      headline: "Software and cloud app support",
      summary: "Installs, updates, licensing and day-to-day troubleshooting for the software and cloud apps your business runs on.",
      includes: [
        "Software installs, updates and licensing",
        "Email and office suite problems",
        "Cloud app setup and troubleshooting",
        "Help for staff stuck on a tool"
      ]
    ),
    Definition.new(
      slug: "accounts-and-security", name: "Accounts, Access & Security", icon: "fa-user-shield",
      headline: "Account, access and security support",
      summary: "New-hire and departing-employee accounts, permissions, password resets and practical security for a small business.",
      includes: [
        "Onboarding and offboarding staff accounts",
        "Permissions and shared access",
        "Password resets and multi-factor setup",
        "Practical security checkups"
      ]
    )
  ].freeze

  def self.find(slug)
    ALL.find { |service| service.slug == slug }
  end

  def self.service_area
    ENV["SERVICE_AREA"].presence
  end

  # " in Phoenix, AZ" when SERVICE_AREA is set, "" otherwise.
  def self.area_suffix
    service_area ? " in #{service_area}" : ""
  end
end
