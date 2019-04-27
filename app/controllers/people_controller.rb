class PeopleController < Devise::RegistrationsController
  class PersonDeleted < StandardError; end

  skip_before_filter :verify_authenticity_token, :only => [:creates]
  skip_before_filter :require_no_authentication, :only => [:new]

  before_filter EnsureCanAccessPerson.new(
    :id, error_message_key: "layouts.notifications.you_are_not_authorized_to_view_this_content"), only: [:update, :destroy]

  skip_filter :cannot_access_if_banned, :only => [ :check_email_availability_and_validity, :check_invitation_code ]
  skip_filter :cannot_access_without_confirmation, :only => [ :check_email_availability_and_validity, :check_invitation_code ]
  skip_filter :ensure_consent_given, :only => [ :check_email_availability_and_validity, :check_invitation_code ]
  skip_filter :ensure_user_belongs_to_community, :only => [ :check_email_availability_and_validity, :check_invitation_code ]

  helper_method :show_closed?

  def show
    @person = Person.find_by_username_and_community_id!(params[:username], @current_community.id)
    raise PersonDeleted if @person.deleted?

    redirect_to root and return if @current_community.private? && !@current_user
    @selected_tribe_navi_tab = "members"
    @community_membership = CommunityMembership.find_by_person_id_and_community_id_and_status(@person.id, @current_community.id, "accepted")

    include_closed = @current_user == @person && params[:show_closed]
    search = {
      author_id: @person.id,
      include_closed: include_closed,
      page: 1,
      per_page: 6
    }

    includes = [:author, :listing_images]
    raise_errors = Rails.env.development?

    listings =
      ListingIndexService::API::Api
      .listings
      .search(
        community_id: @current_community.id,
        search: search,
        engine: search_engine,
        raise_errors: raise_errors,
        includes: includes
      ).and_then { |res|
      Result::Success.new(
        ListingIndexViewUtils.to_struct(
        result: res,
        includes: includes,
        page: search[:page],
        per_page: search[:per_page]
      ))
    }.data

    received_testimonials = TestimonialViewUtils.received_testimonials_in_community(@person, @current_community)
    received_positive_testimonials = TestimonialViewUtils.received_positive_testimonials_in_community(@person, @current_community)
    feedback_positive_percentage = @person.feedback_positive_percentage_in_community(@current_community)

    render locals: { listings: listings,
                     followed_people: @person.followed_people,
                     received_testimonials: received_testimonials,
                     received_positive_testimonials: received_positive_testimonials,
                     feedback_positive_percentage: feedback_positive_percentage
                   }
  end

  def new
    @selected_tribe_navi_tab = "members"
    redirect_to root if logged_in?
    session[:invitation_code] = params[:code] if params[:code]

    @person = if params[:person] then
      Person.new(params[:person].slice(:given_name, :family_name, :email, :username))
    else
      Person.new()
    end

    @container_class = params[:private_community] ? "container_12" : "container_24"
    @grid_class = params[:private_community] ? "grid_6 prefix_3 suffix_3" : "grid_10 prefix_7 suffix_7"
  end

  def create
    domain = @current_community ? @current_community.full_url : "#{request.protocol}#{request.host_with_port}"
    error_redirect_path = domain + sign_up_path

    if params[:person][:input_again].present? # Honey pot for spammerbots
      flash[:error] = t("layouts.notifications.registration_considered_spam")
      ApplicationHelper.send_error_notification("Registration Honey Pot is hit.", "Honey pot")
      redirect_to error_redirect_path and return
    end

    if @current_community && @current_community.join_with_invite_only? || params[:invitation_code]

      unless Invitation.code_usable?(params[:invitation_code], @current_community)
        # abort user creation if invitation is not usable.
        # (This actually should not happen since the code is checked with javascript)
        session[:invitation_code] = nil # reset code from session if there was issues so that's not used again
        ApplicationHelper.send_error_notification("Invitation code check did not prevent submiting form, but was detected in the controller", "Invitation code error")

        # TODO: if this ever happens, should change the message to something else than "unknown error"
        flash[:error] = t("layouts.notifications.unknown_error")
        redirect_to error_redirect_path and return
      else
        invitation = Invitation.find_by_code(params[:invitation_code].upcase)
      end
    end

    # Check that email is not taken
    unless Email.email_available?(params[:person][:email], @current_community.id)
      flash[:error] = t("people.new.email_is_in_use")
      redirect_to error_redirect_path and return
    end

    # Check that the email is allowed for current community
    if @current_community && ! @current_community.email_allowed?(params[:person][:email])
      flash[:error] = t("people.new.email_not_allowed")
      redirect_to error_redirect_path and return
    end

    @person, email = new_person(params, @current_community)

    # Make person a member of the current community
    if @current_community
      membership = CommunityMembership.new(:person => @person, :community => @current_community, :consent => @current_community.consent)
      membership.status = "pending_email_confirmation"
      membership.invitation = invitation if invitation.present?
      # If the community doesn't have any members, make the first one an admin
      if @current_community.members.count == 0
        membership.admin = true
      end
      membership.save!
      session[:invitation_code] = nil
    end

    session[:person_id] = @person.id

    # If invite was used, reduce usages left
    invitation.use_once! if invitation.present?

    Delayed::Job.enqueue(CommunityJoinedJob.new(@person.id, @current_community.id)) if @current_community

    # send email confirmation
    # (unless disabled for testing environment)
    if APP_CONFIG.skip_email_confirmation
      email.confirm!

      redirect_to root
    else
      Email.send_confirmation(email, @current_community)

      flash[:notice] = t("layouts.notifications.account_creation_succesful_you_still_need_to_confirm_your_email")
      redirect_to :controller => "sessions", :action => "confirmation_pending"
    end
  end

  def build_devise_resource_from_person(person_params)
    person_params.delete(:terms) #remove terms part which confuses Devise

    # This part is copied from Devise's regstration_controller#create
    build_resource(person_params)
    resource
  end

  def create_facebook_based
    username = UserService::API::Users.username_from_fb_data(
      username: session["devise.facebook_data"]["username"],
      given_name: session["devise.facebook_data"]["given_name"],
      family_name: session["devise.facebook_data"]["family_name"])

    person_hash = {
      :username => username,
      :given_name => session["devise.facebook_data"]["given_name"],
      :family_name => session["devise.facebook_data"]["family_name"],
      :facebook_id => session["devise.facebook_data"]["id"],
      :locale => I18n.locale,
      :test_group_number => 1 + rand(4),
      :password => Devise.friendly_token[0,20],
      community_id: @current_community.id
    }
    @person = Person.create!(person_hash)
    # We trust that Facebook has already confirmed these and save the user few clicks
    Email.create!(:address => session["devise.facebook_data"]["email"], :send_notifications => true, :person => @person, :confirmed_at => Time.now, community_id: @current_community.id)

    @person.set_default_preferences

    @person.store_picture_from_facebook

    session[:person_id] = @person.id
    sign_in(resource_name, @person)
    flash[:notice] = t("layouts.notifications.login_successful", :person_name => view_context.link_to(@person.given_name_or_username, person_path(@person))).html_safe

    CommunityMembership.create(person: @person, community: @current_community, status: "pending_consent")

    session[:fb_join] = "pending_analytics"
    redirect_to :controller => :community_memberships, :action => :new
  end

  def update
    target_user = Person.find_by_username_and_community_id!(params[:id], @current_community.id)
    # If setting new location, delete old one first
    if params[:person] && params[:person][:location] && (params[:person][:location][:address].empty? || params[:person][:street_address].blank?)
      params[:person].delete("location")
      if target_user.location
        target_user.location.delete
      end
    end

    #Check that people don't exploit changing email to be confirmed to join an email restricted community
    if params["request_new_email_confirmation"] && @current_community && ! @current_community.email_allowed?(params[:person][:email])
      flash[:error] = t("people.new.email_not_allowed")
      redirect_to :back and return
    end

    target_user.set_emails_that_receive_notifications(params[:person][:send_notifications])

    begin
      person_params = params.require(:person).permit(
        :given_name,
        :family_name,
        :street_address,
        :phone_number,
        :image,
        :description,
        { location: [:address, :google_address, :latitude, :longitude] },
        :password,
        :password2,
        { send_notifications: [] },
        { email_attributes: [:address] },
        :min_days_between_community_updates,
        { preferences: [
          :email_from_admins,
          :email_about_new_messages,
          :email_about_new_comments_to_own_listing,
          :email_when_conversation_accepted,
          :email_when_conversation_rejected,
          :email_about_new_received_testimonials,
          :email_about_accept_reminders,
          :email_about_confirm_reminders,
          :email_about_testimonial_reminders,
          :email_about_completed_transactions,
          :email_about_new_payments,
          :email_about_payment_reminders,
          :email_about_new_listings_by_followed_people,
        ] }
      )

      Maybe(person_params)[:location].each { |loc|
        person_params[:location] = loc.merge(location_type: :person)
      }

      m_email_address = Maybe(person_params)[:email_attributes][:address]
      m_email_address.each { |new_email_address|
        # This only builds the emails, they will be saved when `update_attributes` is called
        target_user.emails.build(address: new_email_address, community_id: @current_community.id)
      }

      if target_user.update_attributes(person_params.except(:email_attributes))
        if params[:person][:password]
          #if password changed Devise needs a new sign in.
          sign_in target_user, :bypass => true
        end

        m_email_address.each {
          # A new email was added, send confirmation email to the latest address
          Email.send_confirmation(target_user.emails.last, @current_community)
        }

        flash[:notice] = t("layouts.notifications.person_updated_successfully")

        # Send new confirmation email, if was changing for that
        if params["request_new_email_confirmation"]
            target_user.send_confirmation_instructions(request.host_with_port, @current_community)
            flash[:notice] = t("layouts.notifications.email_confirmation_sent_to_new_address")
        end
      else
        flash[:error] = t("layouts.notifications.#{target_user.errors.first}")
      end
    rescue RestClient::RequestFailed => e
      flash[:error] = t("layouts.notifications.update_error")
    end

    redirect_to :back
  end

  def destroy
    target_user = Person.find_by_username_and_community_id!(params[:id], @current_community.id)
    has_unfinished = TransactionService::Transaction.has_unfinished_transactions(target_user.id)
    return redirect_to root if has_unfinished

    communities = target_user.community_memberships.map(&:community_id)

    # Do all delete operations in transaction. Rollback if any of them fails
    ActiveRecord::Base.transaction do
      UserService::API::Users.delete_user(target_user.id)
      MarketplaceService::Listing::Command.delete_listings(target_user.id)

      communities.each { |community_id|
        PaypalService::API::Api.accounts.delete(community_id: @current_community.id, person_id: target_user.id)
      }
    end

    sign_out target_user
    report_analytics_event('user', "deleted", "by user")
    flash[:notice] = t("layouts.notifications.account_deleted")
    redirect_to root
  end

  def check_username_availability
    respond_to do |format|
      format.json { render :json => Person.username_available?(params[:person][:username], @current_community.id) }
    end
  end

  #This checks also that email is allowed for this community
  def check_email_availability_and_validity
    # this can be asked from community_membership page or new user page
    email = params[:person] && params[:person][:email] ? params[:person][:email] : params[:community_membership][:email]

    available = true

    #first check if the community allows this email
    if @current_community.allowed_emails.present?
      available = @current_community.email_allowed?(email)
    end

    if available
      # Then check if it's already in use
      email_availability(email, @current_community.id)
    else #respond false
      respond_to do |format|
        format.json { render :json => available }
      end
    end
  end

  # this checks that email is not already in use for anyone (including current user)
  def check_email_availability
    email = params[:person] && params[:person][:email_attributes] && params[:person][:email_attributes][:address]
    email_availability(email, @current_community.id)
  end

  def check_invitation_code
    respond_to do |format|
      format.json { render :json => Invitation.code_usable?(params[:invitation_code], @current_community) }
    end
  end

  def show_closed?
    params[:closed] && params[:closed].eql?("true")
  end

  private

  # Create a new person by params and current community
  def new_person(params, current_community)
    person = Person.new

    params[:person][:locale] =  params[:locale] || APP_CONFIG.default_locale
    params[:person][:test_group_number] = 1 + rand(4)
    params[:person][:community_id] = current_community.id

    email = Email.new(:person => person, :address => params[:person][:email].downcase, :send_notifications => true, community_id: current_community.id)
    params["person"].delete(:email)

    person = build_devise_resource_from_person(params[:person])

    person.emails << email

    person.inherit_settings_from(current_community)

    if person.save!
      sign_in(resource_name, resource)
    end

    person.set_default_preferences

    [person, email]
  end

  def email_availability(email, community_id)
    available = Email.email_available?(email, community_id)

    respond_to do |format|
      format.json { render :json => available }
    end
  end
end
