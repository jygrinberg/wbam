class CreateLoadBalancers < ActiveRecord::Migration
  def change
    create_table :load_balancers do |t|
      t.string :loadBalancer_id
      t.string :zone

      t.timestamps
    end
  end
end
