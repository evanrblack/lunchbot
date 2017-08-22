require_relative '../app/initialize'

team = Team.create(
  slack_team_id: ENV['SLACK_TEAM_ID'],
  slack_oauth_token: ENV['SLACK_OAUTH_TOKEN'],
  slack_bot_oauth_token: ENV['SLACK_BOT_OAUTH_TOKEN']
)
