class CreateDeviceIds < ActiveRecord::Migration
  def change
    create_table :device_ids do |t|

      t.timestamps null: false
    end
  end
end
