class DashboardManagerController < ApplicationController

    def get_chart_settings
        chart_number = params[:chart_number]
        dashboard_id = session[:dashboard_id]
        dashboard = Dashboard.find(dashboard_id)

        chart = dashboard.charts.where(dashboard: dashboard, chart_number: chart_number).first
        chart = Chart.create(:dashboard => dashboard) if chart.nil? # lazy instantiation

        render json: chart
        return false
    end

    def new_dashboard
        dashboard = Dashboard.create(name: params[:dashboard][:name])
        session[:dashboard_id] = dashboard.id

        redirect_to "/analyze/index/#{dashboard.id}"
    end

    def remove_dashboard
        dashboard_id = params[:dashboard_id]
        if Dashboard.exists?(dashboard_id) then
            dashboard = Dashboard.find(dashboard_id)
            Chart.where(dashboard: dashboard).destroy_all
            dashboard.delete
        end

        render "_dashboard_dropdown_menu"
        return false
    end

end
