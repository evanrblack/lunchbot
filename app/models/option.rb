class Option < Sequel::Model
  many_to_one :poll
  many_to_one :place

  def validate
    super
    validates_presence %i[poll_id place_id]
    validates_unique %i[poll_id place_id]
  end
end
