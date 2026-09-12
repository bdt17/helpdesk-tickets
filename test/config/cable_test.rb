require "test_helper"

# Guards against reverting to the :async adapter in development or
# production. :async's pub/sub is per-process and in-memory - it silently
# cannot deliver a broadcast from Solid Queue's forked
# dispatcher/worker/scheduler processes (config/puma.rb's
# `plugin :solid_queue`) to a WebSocket connection held by the parent Puma
# process. Every broadcast to TicketUpdatesChannel (EscalationAlertJob,
# TicketCategorizationJob) happens from a Solid Queue job, never inline in
# a request, so this isn't a corner case - it's the only way the feature
# is ever triggered. Confirmed by testing this for real: broadcasts logged
# as sent server-side, the socket's own ping frames proved the connection
# was alive, but the actual message never arrived until the adapter was
# switched to Solid Cable, which polls the shared database table instead
# and so doesn't care which process wrote the row.
class CableConfigTest < ActiveSupport::TestCase
  setup do
    @raw = YAML.unsafe_load(ERB.new(File.read(Rails.root.join("config/cable.yml"))).result)
  end

  test "development does not use the async adapter" do
    refute_equal "async", @raw.dig("development", "adapter"),
      "the :async adapter can't deliver a broadcast from a forked Solid Queue process to Puma's WebSocket connections - see the comment in config/cable.yml"
  end

  test "production does not use the async adapter" do
    refute_equal "async", @raw.dig("production", "adapter")
  end
end
