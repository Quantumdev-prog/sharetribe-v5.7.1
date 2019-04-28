class ConfirmationsController < Devise::ConfirmationsController

  skip_filter :cannot_access_if_banned,
              :cannot_access_without_confirmation,
              :ensure_consent_given,
              :ensure_user_belongs_to_community

  # This is directly copied from Devise::ConfirmationsController
  # to be able to handle better the situations of resending confirmation and
  # confirmation attemt with wrong token.

  # POST /resource/confirmation
  def create
    email_param_present = params[:person] && params[:person][:email]

    # Change the email address
    if email_param_present && ! @current_user.has_email?(params[:person][:email]) && @current_community
      # If user submitted the email change form, change the email before sending again.
      if Email.email_available?(params[:person][:email], @current_community.id)
        if @current_community.email_allowed?(params[:person][:email])
          email = Email.create(:person => @current_user, :address => params[:person][:email], :send_notifications => true, community_id: @current_community.id)
          Email.send_confirmation(email, @current_community)
          flash[:notice] = t("sessions.confirmation_pending.check_your_email")
          redirect_to :controller => "sessions", :action => "confirmation_pending" and return
        else
          flash[:error] = t("people.new.email_not_allowed")
          redirect_to :controller => "sessions", :action => "confirmation_pending" and return
        end
      else
        flash[:error] = t("people.new.email_is_in_use")
        redirect_to :controller => "sessions", :action => "confirmation_pending" and return
      end
    else
      email_to_confirm = @current_user.latest_pending_email_address(@current_community)
      email = Email.find_by_address_and_community_id(email_to_confirm, @current_community.id)
      Email.send_confirmation(email, @current_community)
      flash[:notice] = t("sessions.confirmation_pending.check_your_email")
      redirect_to :controller => "sessions", :action => "confirmation_pending" and return
    end

  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    if params[:confirmation_token]
      #sometimes tests catch extra ' char with link, so remove it if there
      params[:confirmation_token] = params[:confirmation_token].chomp("'")
    end

    #check if this confirmation code matches to additional emails
    if e = Email.find_by_confirmation_token(params[:confirmation_token])
      person = e.person
      e.confirmed_at = Time.now
      e.confirmation_token = nil
      e.save

      # Accept pending community membership if needed
      if @current_community.approve_pending_membership(person, e.address)
        # If the pending membership was accepted now, it's time to send the welcome email, unless creating admin acocunt
        Delayed::Job.enqueue(SendWelcomeEmail.new(person.id, @current_community.id), priority: 5)
      end
      flash[:notice] = t("layouts.notifications.additional_email_confirmed")

      if @current_user && @current_user.has_admin_rights?
        report_to_gtm({event: "admin_email_confirmed"})
        redirect_to getting_started_admin_community_path(:id => @current_community.id) and return
      elsif @current_user # normal logged in user
        redirect_to root and return
      else # no logged in session
        redirect_to login_path and return
      end
    end

    flash[:error] = t("layouts.notifications.confirmation_link_is_wrong_or_used")
    if @current_user
      redirect_to :controller => "sessions", :action => "confirmation_pending"
    else
      redirect_to :root
    end
  end

end
