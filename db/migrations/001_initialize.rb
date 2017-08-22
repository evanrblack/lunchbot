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

    create_table :places do
      primary_key :id, null: false
      foreign_key :team_id, :teams, null: false

      String :name, null: false
      Fixnum :capacity, null: false, default: 10

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique %i[team_id name]
    end

    create_table :polls do
      primary_key :id, null: false
      foreign_key :team_id, :teams, null: false

      DateTime :ends_at, null: false

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

    end

    create_table :options do
      primary_key :id, null: false
      foreign_key :poll_id, :polls, null: false
      foreign_key :place_id, :polls, null: false

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique %i[poll_id place_id]
    end

    create_table :votes do
      primary_key :id, null: false
      foreign_key :option_id, :options, null: false

      String :slack_user_id, null: false
      String :slack_user_name, null: false

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique %i[option_id slack_user_id]
    end

    create_table :events do
      primary_key :id, null: false
      foreign_key :place_id, :places, null: false

      DateTime :departure_time, null: false
      String :slack_channel_id
      String :slack_ts

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    create_table :attendees do
      primary_key :id, null: false
      foreign_key :event_id, :events, null: false, on_delete: :cascade
      foreign_key :driver_id, :attendees, on_delete: :cascade

      String :slack_user_id, null: false
      String :slack_user_name, null: false

      Fixnum :seats, null: false, default: 0

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique %i[event_id slack_user_id]
    end
  end
end
