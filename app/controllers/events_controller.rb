class EventsController < ApplicationController
  layout 'admin'

# TOOD probably want to make this more restrictive
  def checkAccess
  end

  # GET /events
  # GET /events.xml
  def index
    return deny_access unless hasAccess(3)

    @events = Event.find(:all, :order => "date DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events }
    end
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    return deny_access unless hasAccess(2)

    @event = Event.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/new
  # GET /events/new.xml
  def new
    return deny_access unless hasAccess(2)

    @event = Event.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/1/edit
  def edit
    return deny_access unless hasAccess(2)

    @event = Event.find(params[:id])
    render :layout => 'WardAreaBook'
  end

  

  def create_new_family_event
    @event = Event.new(params[:event])
    @event.author = session[:user_id]

    return deny_access unless hasAccess(2) || @event.family.servedBy?(session[:user_id])

    respond_to do |format|
      if @event.save
        #Advance the next milestone if: 
        #    the event is a memberMilestone 
        #    user has a teaching record
        #    this event is the current milestone
        if @template.memberMilestones.include?([@event.category,@event.category]) and 
            @event.family.teaching_record and 
            @event.category == @event.family.teaching_record.membership_milestone
          nextMileStone = @template.getNextMileStone(@event.family)
          @event.family.teaching_record.membership_milestone = nextMileStone[0]
          @event.family.teaching_record.save!
        end
        #flash[:notice] = 'Event was successfully created.'
        format.html { redirect_to(:controller => 'families', 
                                  :action => 'show', :id => @event.family_id)}
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST /events
  # POST /events.xml
  def create
    return deny_access unless hasAccess(2)
    @event = Event.new(params[:event])
    @event.author = session[:user_id]

    respond_to do |format|
      if @event.save
        #flash[:notice] = 'Event was successfully created.'
        format.html { redirect_to(@event) }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /events/1
  # PUT /events/1.xml
  def update
    event = Event.find(params[:id])
    if event.author == session[:user_id] or event.person_id == session[:user_id] or hasAccess(2)
      event.update_attributes(params[:event])
    end

    if params[:redirect] == "list"
      redirect_to events_path
    else
      redirect_to event.family
    end
  end

  #TODO Hack!  There's got to be a more approprate way to do this.
  def remove
    destroy
  end

  # DELETE /events/1
  # DELETE /events/1.xml
  def destroy
    #flash[:notice] = 'Event successfully deleted.'
    @event = Event.find(params[:id])

    return deny_access unless hasAccess(2) || @event.family.servedBy?(session[:user_id])

    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_path }
      format.xml  { head :ok }
    end
  end
end
