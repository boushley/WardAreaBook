class ProgressReport < ActiveRecord::Base
  attr_accessible :attendingSacrament, :endowed, :familyGroupSheet, :gospelPrinciples, :priesthood, :priesthoodInterview, :proxyBaptisms, :responsibility, :reteachLessons, :sealed, :templePrep, :worthinessInterview

  belongs_to :family
end
