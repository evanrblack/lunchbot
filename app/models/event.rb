# A potential group of people interested in going to lunch somewhere
class Event < Sequel::Model
  many_to_one :place
  one_to_many :attendees

  dataset_module do
    subset :active { Sequel::CURRENT_TIMESTAMP < departure_time }
  end

  def validate
    super
    validates_presence %i[place_id departure_time]
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
        actions: ([button] if seats_left > 0)
      }
    end
    # then option to become a driver
    options = [{ text: 'Just me', value: 1 }]
    (2..5).each do |i|
      options << { text: "Me and #{i - 1} more", value: i }
    end
    select = { name: 'seats', text: "I'm driving...", type: 'select', options: options }
    attachments << { text: '', callback_id: "become_driver:#{id}", actions: [select] }
    # put it all together
    message = {
      token: place.team.slack_oauth_token,
      channel: slack_channel_id,
      text: "_Lunch at_ *#{place.name}*",
      attachments: attachments.to_json
    }
  end

  def create_slack_message
    raise 'Message already exists' if slack_ts
    Resque.enqueue(SlackBridge, self.id)
  end

  def update_slack_message
    raise 'No timestamp' unless slack_ts
    Resque.enqueue(SlackBridge, self.id)
  end
end
