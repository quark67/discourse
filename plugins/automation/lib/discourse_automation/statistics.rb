# frozen_string_literal: true

module DiscourseAutomation
  module Statistics
    def self.total
      { count: Automation.count }
    end

    def self.created
      period_counts(Automation.all, :created_at, count: false)
    end

    def self.edited
      period_counts(Automation.where("updated_at > created_at"), :updated_at, count: false)
    end

    def self.executed
      period_counts(Stat.all, :date, count: false) { |scope| scope.distinct.count(:automation_id) }
    end

    def self.executions
      period_counts(Stat.all, :date) { |scope| scope.sum(:total_runs) }
    end

    def self.period_counts(scope, column, count: true, &aggregate)
      aggregate ||= ->(relation) { relation.count }
      col = scope.arel_table[column]
      result = {
        last_day: aggregate.call(scope.where(col.gt(1.day.ago))),
        "7_days": aggregate.call(scope.where(col.gt(7.days.ago))),
        "30_days": aggregate.call(scope.where(col.gt(30.days.ago))),
        previous_30_days: aggregate.call(scope.where(col.between(60.days.ago..30.days.ago))),
      }
      result[:count] = aggregate.call(scope) if count
      result
    end
    private_class_method :period_counts
  end
end
