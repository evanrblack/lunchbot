# A potential group of people interested in going to lunch somewhere
class Event < Sequel::Model
  many_to_one :place
  one_to_many :attendees

  dataset_module do
    def active
      where(closed: false)
    end

    def closed
      where(closed: true)
    end
  end

  def validate
    super
    validates_presence %i[place_id departure_time]
  end

  def departure_time_formatted
    tz = TZInfo::Timezone.get('America/Chicago')
    tz.utc_to_local(departure_time).strftime('%-I:%M %p')
  end

  def to_slack_message
    attachments = []
    # first the current drivers
    attendees_dataset.driving.each do |driver|
      passengers = driver.passengers
      seats_left = driver.seats - 1 - passengers.count
      driver_name = driver.slack_user_name
      passenger_names = passengers.map(&:slack_user_name).join(', ')
      button = {
        type: 'button',
        name: 'driver_id',
        value: driver.id,
        text: "Ride with #{driver_name}"
      }
      attachments << {
        text: "#{driver_name} driving #{passenger_names} (#{seats_left} seats left)",
        callback_id: 'become_passenger',
        actions: ([button] if seats_left > 0 && !closed)
      }
    end

    # then option to become a driver
    options = [{ text: 'Just me', value: 1 }]
    (2..5).each do |i|
      options << { text: "Me and #{i - 1} more", value: i }
    end

    stranded = attendees.select(&:stranded?)
    if stranded.any?
      attachments << { text: "No ride: #{stranded.map(&:slack_user_name).join(', ')}" }
    end

    if !closed
      select = { name: 'seats', text: "I'm driving...", type: 'select', options: options }
      attachments << { text: '', callback_id: "become_driver:#{id}", actions: [select] }
    end

    # put it all together
    segments = [
      "_Lunch at_ *#{place.name}*",
      "#{attendees.count} attending",
      "_#{!closed ? 'leaving' : 'left'} at_ #{departure_time_formatted}"
    ]
    message = {
      token: place.team.slack_oauth_token,
      channel: slack_channel_id,
      text: segments.join(', '),
      attachments: attachments.to_json
    }
  end

  def create_slack_message
    raise 'Message already exists' if slack_ts
    EventPoster.perform_async(self.id)
  end

  def update_slack_message
    raise 'No timestamp' unless slack_ts
    EventPoster.perform_async(self.id)
  end
end
