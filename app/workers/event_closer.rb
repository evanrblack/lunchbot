class EventCloser
  include Sidekiq::Worker

  def perform
    Event.active.where{Sequel::CURRENT_TIMESTAMP > departure_time}.each do |event|
      event.update(closed: true)
      event.update_slack_message
      log "Closed event ##{event.id}: #{event.place.name}"
    end
  end
end
