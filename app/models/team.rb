# A slack team
class Team < Sequel::Model
  one_to_many :places
  one_to_many :polls
  one_to_many :events
end
