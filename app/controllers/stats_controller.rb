class StatsController < ApplicationController
  caches_action :index, :layout => false
  def index 
    @totalMembers  = Person.find_all_by_current(true).length
    @total         = Family.find_all_by_current_and_member(true,true).where("status != 'moved'").length
    @activeFamilies= Family.find_all_by_current_and_member_and_status(true,true,'active')
    @active        = @activeFamilies.length
    @lessActive    = Family.find_all_by_current_and_member_and_status(true,true,'less active').length
    @notInterested = Family.find_all_by_current_and_member_and_status(true,true,'not interested').length
    @dnc           = Family.find_all_by_current_and_member_and_status(true,true,'dnc').length
    @unknown       = Family.find_all_by_current_and_member_and_status(true,true,'unknown').length + 
                     Family.find_all_by_current_and_member_and_status(true,true,'new').length 
  end

  def showActive
    @families = Family.find_all_by_member_and_current_and_status(true,true,"active").order("name")
    render :update do |page|
      page.replace_html("show_stuff", 
                        :partial => "families/list_families",
                        :object => @families)
    end
  end

  def showLessActive
    @families = Family.find_all_by_member_and_current_and_status(true,true,"less active").order("name")
    render :update do |page|
      page.replace_html("show_stuff", 
                        :partial => "families/list_families",
                        :object => @families)
    end
  end

  def showNotInterested
    @families = Family.find_all_by_member_and_current_and_status(true,true,"not interested".order("name")
    render :update do |page|
      page.replace_html("show_stuff", 
                        :partial => "families/list_families",
                        :object => @families)
    end
  end

  def showDNC
    @families = Family.find_all_by_member_and_current_and_status(true,true,"dnc").order("name")
    render :update do |page|
      page.replace_html("show_stuff", 
                        :partial => "families/list_families",
                        :object => @families)
    end
  end

  def showUnknown
    @families = Family.find_all_by_member_and_current_and_status(true,true,"new".order("name")
    render :update do |page|
      page.replace_html("show_stuff", 
                        :partial => "families/list_families",
                        :object => @families)
    end
  end

  def showThisMonth
    @families = Array.new
    Family.visitedWithinTheLastMonths(0).keys.each do |family_id|
      @families << Family.find(family_id)
    end
    render :update do |page|
      page.replace_html("show_stuff", 
                        :partial => "families/list_families",
                        :object => @families)
    end
  end

  def showTwoMonths
    @families = Array.new
    Family.visitedWithinTheLastMonths(1).keys.each do |family_id|
      @families << Family.find(family_id)
    end
    render :update do |page|
      page.replace_html("show_stuff", 
                        :partial => "families/list_families",
                        :object => @families)
    end
  end

  def showThreeMonths
    @families = Array.new
    Family.visitedWithinTheLastMonths(3).keys.each do |family_id|
      @families << Family.find(family_id)
    end
    render :update do |page|
      page.replace_html("show_stuff", 
                        :partial => "families/list_families",
                        :object => @families)
    end
  end

  def showSixMonths
    @visited = Array.new
    Family.visitedWithinTheLastMonths(6).keys.each do |family_id|
      @visited << Family.find(family_id)
    end
    @allMemberFamilies = Family.find_all_by_member_and_current(true,true)
    @families = @allMemberFamilies - @visited
    render :update do |page|
      page.replace_html("show_stuff", 
                        :partial => "families/list_families",
                        :object => @families,
                        :locals => {:header => "#{@families.size} Families Not Visted 
                                    in the Last Six Months"})
    end
  end

  def showYear
    @visited = Array.new
    Family.visitedWithinTheLastMonths(12).keys.each do |family_id|
      @visited << Family.find(family_id)
    end
    @allMemberFamilies = Family.find_all_by_member_and_current(true,true)
    @families = @allMemberFamilies - @visited
    render :update do |page|
      page.replace_html("show_stuff", 
                        :partial => "families/list_families",
                        :object => @families,
                        :locals => {:header => "#{@families.size} Families Not 
                                                 Visted in the Last Year"})
    end
  end
end
