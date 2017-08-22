class Poll < Sequel::Model
  many_to_one :team
  one_to_many :options

  dataset_module do
    subset :active { Sequel::CURRENT_TIMESTAMP < ends_at }
  end

  def validate
    super
    validates_presence %i[team_id ends_at]
  end
end
