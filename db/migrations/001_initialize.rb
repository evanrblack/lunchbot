Sequel.migration do
  change do
    create_table :teams do
      primary_key :id, null: false

      String :slack_team_id, null: false
      String :slack_oauth_token, null: false
      String :slack_bot_oauth_token, null: false

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    create_table :parties do
      primary_key :id, null: false
      foreign_key :team_id, :teams, null: false

      String :place, null: false
      Number :capacity, null: false, default: 10
      DateTime :departs_at, null: false
      String :slack_channel_id
      String :slack_ts

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    create_table :members do
      primary_key :id, null: false
      foreign_key :party_id, :parties, null: false

      String :slack_user_id, null: false
      String :slack_user_name, null: false

      TrueClass :paying, null: false, default: false
      Number :seats, null: false, default: 0

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
