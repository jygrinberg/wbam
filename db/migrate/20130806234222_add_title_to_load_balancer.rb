class AddTitleToLoadBalancer < ActiveRecord::Migration
  def change
    add_column :load_balancers, :title, :string, :default => 'Unknown Service'
  end
end
