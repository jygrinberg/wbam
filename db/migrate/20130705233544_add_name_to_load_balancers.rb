class AddNameToLoadBalancers < ActiveRecord::Migration
  def change
    add_column :load_balancers, :name, :string
  end
end
