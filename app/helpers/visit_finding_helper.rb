module VisitFindingHelper

  def getLastVisitingTeachingEvent(person)
    return nil if person.visiting_teachers.empty?

    visitingTeachers = person.visiting_teachers.all

    clause = "category ='Visiting Teaching' and ("
    clause += visitingTeachers.collect { |vt| 'person_id = ' + vt.id.to_s.to_s }.join(' or ')
    clause += ")"

    person.family.events.where(clause).order('date DESC').first
  end

  def getLastHomeTeacherVisit(family)
    return nil if family.teaching_routes.empty?

    clause = "category = 'Home Teaching' and ("
    clause += family.teaching_routes.collect { |route| 'person_id = ' + route.person.id.to_s }.join(' or ')
    clause += ")"

    family.events.where(clause).order('date DESC').first
  end
end

