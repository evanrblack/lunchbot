class SlackBridge
  @queue = :events

  def self.perform(event_id)
    event = Event.find(id: event_id)
    !event.slack_ts ? self.create(event) : self.update(event)
  end

  def self.create(event)
    url = 'https://slack.com/api/chat.postMessage'
    data = event.to_slack_message
    response = Faraday.post(url, data)
    event.update(slack_ts: JSON.parse(response.body)['ts'])
  end

  def self.update(event)
    url = 'https://slack.com/api/chat.update'
    data = event.to_slack_message.merge(ts: event.slack_ts)
    response = Faraday.post(url, data)
  end
end
