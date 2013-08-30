class Alarm < ActiveRecord::Base
    attr_accessible :metric, :period, :threshold, :relation, :min_length_sec, :priority

    belongs_to :metric

    validates :metric, presence: true

    def description
        return "#{self.metric.metric_name} (#{self.metric.data_type}) #{self.relation} #{self.threshold}#{self.metric.unit_pretty} "
    end
end
