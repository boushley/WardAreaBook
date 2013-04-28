require 'mechanize'
require 'date'
require 'json'
require_relative 'json_person'

class WardListImporter
  UPDATEDIR = "#{Rails.root}/db/updateScripts/"
  SIGN_IN_URL = "https://signin.lds.org/SSOSignIn/"

  # TODO Eventually this needs to be made multi-tenant so that it can work for multiple wards,
  # for now we'll just use a constant for the ward id
  ORGANIZATIONS_TO_GET = [1179, 69, 70, 73, 74, 75, 76, 77, 1310]
  DEFAULT_PERMISSION_LEVEL = 1
  # CALLING => POSITION_ID
  # Bishop => 4
  # 1st counselor => 54
  # 2nd counselor => 55
  # Exec Sec => 56
  # Ward Clerk => 57
  # RS Pres => 143
  # HPGL => 133
  # EQP => 138
  # Ward Mission Leader => 221
  # Primary Pres => 210
  # YW Pres => 183
  # YM Pres => 158
  # SS Pres => 204
  POSITION_TO_LEVEL = {
    "4" => 3,
    "54" => 3,
    "55" => 3,
    "56" => 3,
    "57" => 3,
    "143" => 2,
    "133" => 2,
    "138" => 2,
    "221" => 2,
    "210" => 2,
    "183" => 2,
    "158" => 2,
    "204" => 2,
  }

  def initialize(root_admin)
    @root_admin = root_admin
    @agent = Mechanize.new
  end

  def run
    sign_in
    setup_ward_directory
    download_ward_list
    download_leadership_info
    download_families

    process_ward
    parse_callings
  end

  private

  def sign_in
    puts "Signing In At #{SIGN_IN_URL}"
    @agent.get(SIGN_IN_URL) do |page|
      form = page.forms.find do |f|
        f.dom_id == "loginForm"
      end

      form.username = @root_admin.lds_user_name
      form.password = @root_admin.lds_password 
      result_page = @agent.submit(form)

      # Currently the easiest to detect difference I found was that when you successfully log in
      # there is a meta refresh tag, and when you fail to log in there is not. If this behavior changes
      # then this could cause problems
      successful_log_in = result_page.meta_refresh.size > 0

      raise 'Login Failed. Unable to proceed with database update.' unless successful_log_in
    end
  end

  def setup_ward_directory
    FileUtils.rm_rf(ward_location + ".old") if File.exists? ward_location + ".old"
    FileUtils.mv(ward_location, ward_location + ".old") if File.exists? ward_location
    Dir.mkdir(ward_location)
  end

  def download_ward_list
    @agent.get("https://lds.org/directory/services/ludrs/mem/member-list/#{@root_admin.ward_id}").save_as(list_location)
    puts "Just retrieved the ward list for #{@root_admin.ward_id}"
  end

  def download_leadership_info
    puts "Getting leadership information"

    Dir.mkdir(callings_location)

    ORGANIZATIONS_TO_GET.each do |org_id|
      @agent.get("https://www.lds.org/directory/services/ludrs/1.1/unit/stake-leadership-group-detail/#{@root_admin.ward_id}/#{org_id}/1").save_as("#{callings_location}/#{org_id}.json")
      puts "just retrieved callings for ward: #{@root_admin.ward_id} org: #{org_id}"
    end
  end

  def parse_ward
    jsonString = File.open(list_location, "r").read
    JSON.parse(jsonString)
  end

  def download_families
    parse_ward.each do |json_entry|
      download_family_info json_entry['headOfHouseIndividualId']
    end
  end

  def process_ward
    # set all records to non current
    Family.where(:ward_id => @root_admin.ward_id, :member => true).update_all(:current => false)

    parse_ward.each do |json_entry|
      process_family json_entry
    end

    # Get all of the non-current families. 
    # Find all that don't have a status of "Moved - Old Record" and print those to a report
    # change status of those families to   "Moved - Old Record"
    moved = Family.where({current: false, member: true, ward_id: @root_admin.ward_id}).where("status != '#{Family::MOVED_STATUS}'")

    unless moved.empty? 
      puts "\tFamilies moved out:"
      moved.each do |family|
        puts "\t\t" + family.name + "," + family.head_of_house_hold
        family.status = Family::MOVED_STATUS
        family.events.create(:date => Date.today,
                             :category => "MoveOut",
                             :comment => "Records removed from the Ward")
        # make all of the family members not current
        Person.update_all({:current => false}, {:family_id => family.id})
        family.save
      end
    end

  end

  def process_family list_entry
    uid = list_entry['headOfHouseIndividualId']
    coupleName = list_entry['coupleName']
    lastName, headOfHouseHold = coupleName.split(/,/)
    lastName.strip!
    headOfHouseHold.strip!
    headOfHouseHold.gsub!("&", "and")

    family_info = parse_family_info uid

    household_info = family_info['householdInfo']
    family_email = household_info['email']
    phone = household_info['phone']

    address_info = household_info['address']
    address = address_info['addr1'] + " " + address_info['addr2']

    # TODO Not sure if all of these defaults are really necessary
    lastName ||= "" 
    headOfHouseHold ||= "" 
    phone ||= "" 
    address ||= "" 

    puts "Processing Family #{uid} -- #{lastName}"

    family = Family.find_by_uid(uid)
    family_is_new = false

    unless family
      family = Family.new
      family.status = 'new'
      family.uid = uid
      family_is_new = true
    end

    family.ward_id = @root_admin.ward_id
    family.name = lastName
    family.head_of_house_hold = headOfHouseHold
    family.phone = phone
    family.address = address
    family.status = "Returned Record" if family.status == Family::MOVED_STATUS
    family.current=true
    family.member=true
    family.save

    if family_is_new
      family.events.create(:date => Date.today, :category => "MoveIn", :comment => "Received records from SLC")
    end

    ########################
    # Update Family members
    #
    # Make all family members not current and then make them
    # current if they appear in new ward list.
    # For my report I want a list of those people already removed
    Person.where(:family_id => family.id).update_all(:current => false)

    familyMembers = JsonPerson.get_family_members(list_entry, family_info)
    familyMembers.each do |fm| 
      puts "\tProcessing person #{fm.uid} -- #{fm.name}"
      person = Person.where(:uid => fm.uid).first

      unless person
        person = Person.new
        person.family_id = family.id
        person.uid = fm.uid
      end

      # If this is the head of household, then setup the household email for them
      email_to_use = fm.email
      if fm.uid == uid && email_to_use.to_s.empty?
        email_to_use = family_email
      end

      person.name = fm.name
      person.email = email_to_use
      person.phone = fm.phone
      person.current = true
      person.save
    end # End familyMembers.each
  end

  def parse_callings
    puts "Parsing Calings"

    unless File.directory?(callings_location)
      puts "Missing callings folder #{callings_location}, can't parse callings"
      return
    end

    Dir.foreach(callings_location) do |filename|
      fullFileName = File.join(callings_location, filename)
      puts "Skipping because its a directory: #{fullFileName}" if File.directory?(fullFileName)
      next if File.directory?(fullFileName)

      puts "Parsing callings out of: #{fullFileName}"

      jsonString = File.open(fullFileName, "r").read
      callings = JSON.parse(jsonString)

      callings['leaders'].each do |json_entry|
        personId = Person.where(:uid => json_entry['individualId']).first.id
        positionId = json_entry['positionId']

        # This positionId is used for many different callings, so it is essentially meaningless
        next if positionId == 999999

        cal = Calling.where(:position_id => positionId).first
        callingName = json_entry['callingName']

        puts "Mapping person id: #{personId} to #{callingName}(#{positionId})"

        if cal
          cal.calling_assignments.build(:person_id => personId)
          # If the calling_assignment already exists, save returns false; we don't want an exception here
          cal.save
        else
          level = POSITION_TO_LEVEL[positionId.to_s] || DEFAULT_PERMISSION_LEVEL
          new_cal = Calling.create(:job => callingName, :position_id => positionId, :access_level => level)
          new_cal.save!
        end
      end
    end
  end

  def download_family_info uid
    puts "Downloading info for family: #{uid}"
    @agent.get("https://www.lds.org/directory/services/ludrs/mem/householdProfile/#{uid}").save_as("#{ward_location}/#{uid}.json")
  end

  def parse_family_info uid
    jsonString = File.open("#{ward_location}/#{uid}.json", "r").read
    JSON.parse(jsonString)
  end

  def ward_location
    "#{UPDATEDIR}#{@root_admin.ward_id}"
  end

  def callings_location
    "#{ward_location}/callings"
  end

  def list_location
    "#{ward_location}/WardList.json"
  end
end
