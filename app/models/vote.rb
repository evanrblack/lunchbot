class Vote < Sequel::Model
  many_to_one :option

  def validate
    super
    validates_presence %i[option_id slack_user_id slack_user_name]
    validates_unique %i[option_id slack_user_id]
  end
end
