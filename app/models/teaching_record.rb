class TeachingRecord < ActiveRecord::Base
  belongs_to :family
  belongs_to :person
  serialize :lessons_taught
end
