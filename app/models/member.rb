# A member of a party
class Member < Sequel::Model
  many_to_one :party

  def validate
    super
    validates_presence %i[slack_user_id slack_user_name paying seats]
    validates_includes [false, true], :paying
    validates_includes 0..5, :seats
    validates_not_in_other_party
  end

  private

  def validates_not_in_other_party
    query = Sequel.lit('id != ? AND departs_at < ?', party_id, Time.now)
    in_another_party = Party.where(query).flat_map(&:members).include? self
    errors.add('Already a member of a current party') if in_another_party
  end
end
