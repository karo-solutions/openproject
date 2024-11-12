class RecurringMeeting < ApplicationRecord
  include ::Meeting::VirtualStartTime
  belongs_to :project
  belongs_to :author, class_name: "User"

  before_save :update_start_time!

  validates_presence_of :start_time, :title, :frequency, :end_after
  validates_presence_of :end_date, if: -> { end_after_specific_date? }
  validates_numericality_of :iterations, if: -> { end_after_iterations? }

  enum frequency: {
    daily: 0,
    weekly: 1,
    biweekly: 2,
    monthly: 3,
    yearly: 4
  }.freeze, _prefix: true

  enum end_after: {
    specific_date: 0,
    iterations: 1
  }.freeze, _prefix: true

  has_many :meetings, inverse_of: :recurring_meeting

  scope :visible, ->(*args) {
    includes(:project)
      .references(:projects)
      .merge(Project.allowed_to(args.first || User.current, :view_meetings))
  }

  # Keep location and duration as a virtual attribute
  # so it can be passed to the template on save
  virtual_attribute :location do
    nil

  end
  virtual_attribute :duration do
    nil
  end

  def schedule
    IceCube::Schedule.new(start_time, end_time: end_date).tap do |s|
      s.add_recurrence_rule count_rule(frequency_rule)
    end
  end

  private

  def frequency_rule
    IceCube::Rule.public_send(frequency)
  end

  def count_rule(rule)
    if end_after_iterations?
      rule.count(iterations)
    else
      rule
    end
  end
end
