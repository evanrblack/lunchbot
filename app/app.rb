require_relative 'initialize'

TOKEN = ENV['SLACK_VERIFICATION_TOKEN']

class App < Sinatra::Base
  post '/commands' do
    @payload = params
    validate_from_slack(@payload['token'])

    create_event
  end

  post '/actions' do
    @payload = JSON.parse(params['payload'])
    validate_from_slack(@payload['token'])

    case @payload['callback_id']
    when /become_driver/
      become_driver
    when 'become_passenger'
      become_passenger
    end
  end

  private

  def create_event
    team = Team.find(slack_team_id: @payload['team_id'])

    place_name, time_string = @payload['text'].split(',').map(&:strip)
    return "Please type the command like this: `/lunch place, time`"unless place_name && time_string

    tz = TZInfo::Timezone.get(team.time_zone)
    digits_only = time_string.tr('^0-9', '')
    if time_string.length <= 2
      # hour only
      hour = digits_only.to_i
      minute = 0
    elsif time_string.length == 3
      # one digit hour
      hour = digits_only[0].to_i
      minute = digits_only[1..2].to_i
    else
      hour = digits_only[-4..-3].to_i
      minute = digits_only[-2..-1].to_i
    end

    hour = hour % 12
    minute = minute < 60 ? minute : 0

    input_total_minute = hour * 60 + minute
    tz_total_minute = tz.now.hour * 60 + tz.now.min
    if (input_total_minute < tz_total_minute)
      hour += 12
    end

    departure_time = tz.local_time(tz.now.year, tz.now.month, tz.now.day, hour, minute)

    closest, distance = Place.all
      .map { |p| [p, Levenshtein.distance(place_name, p.name)] }
      .min { |a, b| a[1] <=> b[1] }
    place = if (closest && distance < 2)
              closest
            else
              Place.create(team: team, name: place_name, capacity: 10)
            end

    Event.create(
      place_id: place.id,
      departure_time: departure_time,
      slack_channel_id: @payload['channel_id']
    ).create_slack_message

    return 200
  end

  def become_passenger
    slack_user_id = @payload['user']['id']
    slack_user_name = @payload['user']['name']
    driver = Attendee.find(id: @payload['actions'][0]['value'])
    event = driver.event

    # look for same user in another active event
    event_ids = Event.active.map(&:id)
    attendee = Attendee.find(event_id: event_ids, slack_user_id: slack_user_id)
    if attendee
      # already in active event
      if attendee != driver
        # not their own driver
        old_event = attendee.event
        old_passengers = []
        if attendee.seats > 0
          # but were a driver
          old_passengers = attendee.passengers
        end
        attendee.update(seats: 0, event_id: event.id, driver_id: driver.id)
        old_passengers.each { |p| p.update(driver: nil) }
        old_event.update_slack_message if old_event.id != event.id
      end
    else
      # not in active event
      Attendee.create(
        slack_user_id: slack_user_id,
        slack_user_name: slack_user_name,
        seats: 0,
        event_id: event.id,
        driver_id: driver.id,
      )
    end
    event.update_slack_message

    return 200
  end

  def become_driver
    slack_user_id = @payload['user']['id']
    slack_user_name = @payload['user']['name']
    seats = @payload['actions'].first['selected_options'].first['value'].to_i
    event = Event.find(id: @payload['callback_id'].split(':').last)
    
    # look for same user in another active event
    event_ids = Event.active.map(&:id)
    attendee = Attendee.find(event_id: event_ids, slack_user_id: slack_user_id)
    if attendee
      old_event_id = attendee.event_id
      old_passengers = attendee.passengers
      attendee.update(event_id: event.id, driver: nil, seats: seats)
      if old_event_id != event.id
	Event.find(id: old_event_id).update_slack_message
	old_passengers.each { |p| p.update(driver: nil) }
      end
    else
      Attendee.create(
	event_id: event.id,
	seats: seats,
	slack_user_id: slack_user_id,
	slack_user_name: slack_user_name
      )
    end
    event.update_slack_message

    return 200
  end

  def validate_from_slack(token)
    halt 403 if token != TOKEN
  end

  def selected_options(actions)
    actions.map do |action|
      action['selected_options']
    end
  end
end
