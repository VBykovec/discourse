require_dependency 'enum'
require_dependency 'reviewable_actions'

class Reviewable < ActiveRecord::Base
  validates_presence_of :type, :status, :created_by_id
  belongs_to :target, polymorphic: true
  belongs_to :created_by, class_name: 'User'

  def self.statuses
    @statuses ||= Enum.new(
      pending: 0,
      approved: 1,
      rejected: 2,
      ignored: 3,
      deleted: 4
    )
  end

  # Generate `pending?`, `rejected?` helper methods
  statuses.each do |name, id|
    define_method("#{name}?") { status == id }
  end

  def actions_for(guardian)
    actions = ReviewableActions.new(self, guardian)
    build_actions(actions, guardian)
    actions
  end

  # subclasses implement "build_actions" to list the actions they're capable of
  def build_actions
  end

  def self.list_for(user, status: :pending)
    return [] if user.blank?

    filtered = where(status: statuses[status]).includes(:target)

    return filtered if user.admin?

    filtered.where(
      '(reviewable_by_moderator AND :staff) OR (reviewable_by_group_id IN (:group_ids))',
      staff: user.staff?,
      group_ids: user.group_users.pluck(:group_id)
    )
  end

end
