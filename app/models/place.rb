class Place < Sequel::Model
  many_to_one :team
  one_to_many :events

  def validate
    super
    validates_presence %i[team_id name capacity]
    validates_integer :capacity
    validates_unique %i[team_id name]
  end
end
