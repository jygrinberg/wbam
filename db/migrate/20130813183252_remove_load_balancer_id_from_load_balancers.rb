class RemoveLoadBalancerIdFromLoadBalancers < ActiveRecord::Migration
  def change
    remove_column :load_balancers, :loadBalancer_id, :integer
  end
end
