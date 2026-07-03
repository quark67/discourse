# frozen_string_literal: true

module DiscourseWorkflows
  module Statistics
    def self.total
      { count: Workflow.count }
    end

    def self.created
      period_counts(Workflow.all, :created_at, count: false)
    end

    def self.edited
      period_counts(
        WorkflowVersion.where("version_number > 1"),
        :created_at,
        count: false,
      ) { |scope| scope.distinct.count(:workflow_id) }
    end

    def self.executed
      period_counts(ExecutionStat.all, :date, count: false) do |scope|
        scope.distinct.count(:workflow_id)
      end
    end

    def self.executions
      period_counts(ExecutionStat.all, :date) { |scope| scope.sum(:total_runs) }
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
