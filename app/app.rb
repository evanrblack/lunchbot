require_relative 'initialize'

TOKEN = ENV['SLACK_VERIFICATION_TOKEN']

class App < Sinatra::Base
  post '/commands' do
    create_party
  end

  post '/actions' do
    join_party
  end

  private

  def create_party
    validate_from_slack(params['token'])
    puts params
    team = Team.find(slack_team_id: params['team_id'])
    Party.create(
      team: team,
      place: params['text'],
      capacity: 10,
      departs_at: Time.now + 30 * 60,
      slack_channel_id: params['channel_id']
    ).create_slack_message()
    return 200
  end

  def join_party
    payload = JSON.parse(params['payload'])
    validate_from_slack(payload['token'])
    party = Party.find(id: payload['callback_id'].split(':').last)
    seats = payload['actions'].first['selected_options'].first['value'].to_i
    
    # look for same user in currently active party
    slack_user_id = payload['user']['id']
    slack_user_name = payload['user']['name']
    party_ids = Party.active.map(&:id)
    member = Member.find(party_id: party_ids, slack_user_id: slack_user_id)
    if member
      old_party_id = member.party_id
      member.update(party_id: party.id, seats: seats)
      Party.find(id: old_party_id).update_slack_message if old_party_id != party.id
    else
      member = Member.create(
        party: party,
        seats: seats,
        paying: false,
        slack_user_id: slack_user_id,
        slack_user_name: slack_user_name
      )
    end
    party.update_slack_message
    return 200
  end

  def validate_from_slack(token)
    halt 403 if token != TOKEN
  end
end
