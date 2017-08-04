# A slack team
class Team < Sequel::Model
  one_to_many :parties
end
