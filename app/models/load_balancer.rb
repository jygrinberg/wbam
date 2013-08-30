class LoadBalancer < ActiveRecord::Base
	attr_accessible :zone, :name, :title, :created_at, :updated_at

	has_many :datapoints
	has_many :instances

    validates :name, :presence => true, :uniqueness => true

    after_initialize :default_values

    def default_values
        self.name ||= 'Load Balancer'
        self.title ||= 'Unknown Service'
        return true
    end
end
