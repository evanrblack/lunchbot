# An attendee of an event
class Attendee < Sequel::Model
  many_to_one :event
  many_to_one :driver, class: self
  one_to_many :passengers, key: :driver_id, class: self

  dataset_module do
    def driving
      where(Sequel.lit('driver_id IS NULL AND seats > 0'))
    end

    def riding
      where(Sequel.lit('driver_id IS NOT NULL AND seats IS 0'))
    end

    def abandoned
      where(Sequel.lit('driver_id IS NULL AND seats IS 0'))
    end
  end

  def validate
    super
    validates_presence %i[event_id slack_user_id slack_user_name seats]
    validates_unique %i[event_id slack_user_id]
    validates_includes 0..5, :seats
    validates_not_attending_other_event
  end

  def before_update
    super
    where(driver_id: id).update(driver_id: nil) if driver_id
  end

  def driving?
    !driver_id && seats
  end

  def riding?
    driver_id && !seats
  end

  def abandoned?
    !driver_id && !seats
  end

  private

  def validates_not_attending_other_event
    attending_another = Event.active.flat_map(&:attendees).include? self
    errors.add('Already attending another event') if attending_another
  end
end
