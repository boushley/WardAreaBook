class CreateProgressReports < ActiveRecord::Migration
  def change
    create_table :progress_reports do |t|
      t.date :worthinessInterview
      t.date :priesthoodInterview
      t.date :gospelPrinciples
      t.date :reteachLessons
      t.date :responsibility
      t.date :attendingSacrament
      t.date :familyGroupSheet
      t.date :priesthood
      t.date :proxyBaptisms
      t.date :templePrep
      t.date :endowed
      t.date :sealed
      t.integer :family_id
      t.references :family, index: true

      t.timestamps
    end
  end
end
