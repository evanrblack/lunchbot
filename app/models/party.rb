# A potential group of people interested in going to lunch somewhere
class Party < Sequel::Model
  many_to_one :team
  one_to_many :members

  dataset_module do
    subset :active { Sequel::CURRENT_TIMESTAMP < departs_at }
  end

  def validate
    super
    validates_presence %i[place capacity departs_at]
  end

  def departed?
    departs_at < Time.now
  end

  def seats
    members.sum(&:seats)
  end

  def to_slack_message
    options = [{ text: 'No ride', value: 0 }, { text: 'Just me', value: 1 }]
    (2..5).each do |i|
      options << { text: "#{i} seats", value: i }
    end
    select = { name: 'seats', text: "Transportation?", type: 'select', options: options }
    actions = [select]
    text = "#{place} (#{members.count} people/#{seats} seats/#{capacity} spots)"
    ratio = (members.count.to_f / capacity.to_f)
    ceil = [ratio * 255, 255].min
    color = '#%02x%02x%02x' % [0, ceil, 0]
    input = {
      text: text,
      fallback: text,
      callback_id: "party:#{id}",
      actions: actions,
      color: color 
    }
    text = members.map { |m| "#{m.slack_user_name} (#{m.seats} seat#{'s'})" }.join(', ')
    details = {
      text: text,
      fallback: text
    }
    attachments = [input, details].to_json
    { token: team.slack_oauth_token, channel: slack_channel_id, attachments: attachments }
  end

  def create_slack_message
    raise 'Message already exists' if slack_ts
    url = 'https://slack.com/api/chat.postMessage'
    response = Faraday.post(url, to_slack_message)
    update(slack_ts: JSON.parse(response.body)['ts'])
  end

  def update_slack_message
    raise 'No timestamp' unless slack_ts
    url = 'https://slack.com/api/chat.update'
    response = Faraday.post(url, to_slack_message.merge(ts: slack_ts))
  end
end
