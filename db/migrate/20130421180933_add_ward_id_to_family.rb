class AddWardIdToFamily < ActiveRecord::Migration
  def change
    add_column :families, :ward_id, :string
  end
end
