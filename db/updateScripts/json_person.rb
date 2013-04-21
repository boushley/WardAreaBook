class JsonPerson
  attr_accessor :name, :email, :uid, :lastName, :phone
  def initialize(list_entry, details_entry)
    @name = list_entry['preferredName']
    @uid = list_entry['individualId']
    @email = details_entry['email']
    @phone = details_entry['phone']
    @lastName, @name = @name.split(/,/)
    @name.strip!
    @email.strip!
    if @email.empty? 
      @email = nil 
    else
      @email.downcase!
    end
    #@uid.strip!
    @lastName.strip!
    #puts "\t#{name} \t#{id} \t#{email}"
  end

  def self.get_family_members(list_entry, details_entry)
    familyMembers = []
    familyMembers << JsonPerson.new(list_entry['headOfHouse'], details_entry['headOfHousehold'])
    familyMembers << JsonPerson.new(list_entry['spouse'], details_entry['spouse']) if list_entry['spouse']

    list_children = list_entry['children']
    detail_others = details_entry['otherHouseholdMembers']

    if list_children.size != detail_others.size
      puts "We don't have the same number of list children as we have others for the house details."
    end

    list_children.each do |lc|
      details_index = detail_others.index { |o| o['individualId'] == lc['individualId'] }

      if details_index.nil?
        puts "Unabled to find details for family member: #{lc.inspect}"
        next
      end

      d = detail_others[details_index]
      familyMembers << JsonPerson.new(lc, d)
    end

    children.each do |child|
      familyMembers << JsonPerson.new(child)
    end

    return familyMembers
  end

end
