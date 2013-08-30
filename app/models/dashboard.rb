class Dashboard < ActiveRecord::Base
    attr_accessible :name, :rows, :cols, :toggle_chart_forms, :toggle_presenter_mode, :toggle_alarm_mode
    has_many :charts

    validates :name, :presence => true, :uniqueness => true
    validates :rows, :numericality => { :greater_than => 0 }
    validates :cols, :numericality => { :greater_than => 0 }

    after_initialize :default_values

    def default_values
        self.rows ||= 1
        self.cols ||= 1
        self.toggle_chart_forms = true if self.toggle_chart_forms.nil?
        self.toggle_presenter_mode = false if self.toggle_presenter_mode.nil?
        self.toggle_alarm_mode = false if self.toggle_alarm_mode.nil?
        return true
    end

end
