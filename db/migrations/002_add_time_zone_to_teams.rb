Sequel.migration do
  change do
    add_column :teams, :time_zone, String, null: false, default: 'America/Chicago'
  end
end
