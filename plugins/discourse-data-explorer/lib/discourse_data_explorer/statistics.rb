# frozen_string_literal: true

module DiscourseDataExplorer
  module Statistics
    def self.queries_total
      { count: user_queries.count }
    end

    def self.queries_created
      period_counts(user_queries, :created_at, count: false)
    end

    def self.queries_edited
      period_counts(user_queries.where("updated_at > created_at"), :updated_at, count: false)
    end

    def self.queries_executed
      period_counts(user_query_stats, :date, count: false) do |scope|
        scope.distinct.count(:query_id)
      end
    end

    def self.executions
      period_counts(user_query_stats, :date) { |scope| scope.sum(:total_runs) }
    end

    def self.user_query_stats
      QueryStat.where("query_id > 0")
    end

    def self.user_queries
      Query.where(hidden: false).where("id > 0")
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
    private_class_method :user_queries, :user_query_stats, :period_counts
  end
end
