class Metric < ActiveRecord::Base
	attr_accessible :metric_name, :namespace, :data_type, :unit, :target
	has_many :datapoints
    has_many :alarms

    validates_uniqueness_of :metric_name, :scope => [:namespace, :data_type, :unit, :target]

    def unit_pretty
        return '%' if unit == 'Percent'
        return ' ' + unit.downcase
    end

end
