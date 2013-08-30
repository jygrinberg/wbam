class AddLoadBalancerToInstances < ActiveRecord::Migration
  def change
    add_column :instances, :loadBalancer_id, :integer
  end
end
