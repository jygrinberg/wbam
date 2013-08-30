class Instance < ActiveRecord::Base
	attr_accessible :zone, :name, :title, :loadBalancer, :created_at, :updated_at, :stopped_at

	has_many :datapoints
	belongs_to :loadBalancer

    validates :name, :presence => true, :uniqueness => true

    after_initialize :default_values

    def default_values
        self.name ||= 'Instance'
        self.title ||= 'Unknown Service'
        return true
    end
end
