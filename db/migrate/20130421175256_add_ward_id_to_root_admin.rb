class AddWardIdToRootAdmin < ActiveRecord::Migration
  def change
    add_column :root_admins, :ward_id, :string
  end
end
