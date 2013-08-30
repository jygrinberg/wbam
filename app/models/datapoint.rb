class Datapoint < ActiveRecord::Base
	attr_accessible :metric, :instance, :loadBalancer, :timestamp, :period, :value
	belongs_to :metric
	belongs_to :instance
	belongs_to :loadBalancer

    validates_uniqueness_of :timestamp, :scope => [:period, :metric, :instance, :loadBalancer]

end
