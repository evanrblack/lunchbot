class EventPoster
  include Sidekiq::Worker

  def perform(event_id)
    event = Event.find(id: event_id)
    !event.slack_ts ? create_post(event) : update_post(event)
  end

  def create_post(event)
    url = 'https://slack.com/api/chat.postMessage'
    data = event.to_slack_message
    response = Faraday.post(url, data)
    event.update(slack_ts: JSON.parse(response.body)['ts'])
  end

  def update_post(event)
    url = 'https://slack.com/api/chat.update'
    data = event.to_slack_message.merge(ts: event.slack_ts)
    response = Faraday.post(url, data)
  end
end
