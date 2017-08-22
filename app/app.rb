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
    closest, distance = Place.all
      .map { |p| [p, Levenshtein.distance(@payload['text'], p.name)] }
      .min { |a, b| a[1] <=> b[1] }
    place = if (closest && distance < 7)
              closest
            else
              Place.create(team: team, name: @payload['text'], capacity: 10)
            end
    Event.create(
      place_id: place.id,
      departure_time: Time.now + 30 * 60,
      slack_channel_id: @payload['channel_id']
    ).create_slack_message
    return 200
  end

  def become_passenger
    slack_user_id = @payload['user']['id']
    slack_user_name = @payload['user']['name']

    puts @payload

    # look for same user in currently active event
    return 200
  end

  def become_driver
    event = Event.find(id: @payload['callback_id'].split(':').last)
    seats = @payload['actions'].first['selected_options'].first['value'].to_i
    
    # look for same user in currently active event
    slack_user_id = @payload['user']['id']
    slack_user_name = @payload['user']['name']
    event_ids = Event.active.map(&:id)
    puts event_ids
    attendee = Attendee.find(event_id: event_ids, slack_user_id: slack_user_id)
    if attendee
      old_event_id = attendee.event_id
      attendee.update(event_id: event.id, seats: seats)
      Event.find(id: old_event_id).update_slack_message if old_event_id != event.id
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
