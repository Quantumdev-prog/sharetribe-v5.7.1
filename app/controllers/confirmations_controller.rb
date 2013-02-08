class ConfirmationsController < Devise::ConfirmationsController
  
  skip_filter :check_email_confirmation, :cannot_access_without_joining
  skip_filter :dashboard_only
  skip_filter :single_community_only
  
  # This is directly copied from Devise::ConfirmationsController
  # to be able to handle better the situations of resending confirmation and
  # confirmation attemt with wrong token.
  
  # POST /resource/confirmation
  def create
    if params[:person] && params[:person][:email] && params[:person][:email] != @current_user.email && @current_community
      # If user submitted the email change form, change the email before sending again.
      if Person.email_available?(params[:person][:email])
        if @current_community.email_allowed?(params[:person][:email])
          @current_user.update_attribute(:email, params[:person][:email])
        else
          flash[:error] = t("people.new.email_not_allowed")
          redirect_to :controller => "sessions", :action => "confirmation_pending" and return
        end
      else
        flash[:error] = t("people.new.email_is_in_use")
        redirect_to :controller => "sessions", :action => "confirmation_pending" and return
      end
    end
    
    # If looks like were confirming here a company email on dashboard, send manually 
    if session[:unconfirmed_email] && 
           session[:allowed_email] &&
           session[:unconfirmed_email].match(session[:allowed_email]) && 
           @current_user.has_email?(params[:person][:email]) 
      @current_user.send_email_confirmation_to(params[:person][:email], request.host_with_port)
      flash[:notice] = t("sessions.confirmation_pending.account_confirmation_instructions_dashboard")
      redirect_to new_tribe_path and return
    else
      self.resource = resource_class.send_confirmation_instructions(resource_params)
    end

    if successfully_sent?(resource)
      #respond_with({}, :location => after_resending_confirmation_instructions_path_for(resource_name))
      if on_dashboard?
        flash[:notice] = t("sessions.confirmation_pending.account_confirmation_instructions_dashboard")
        redirect_to new_tribe_path and return
      else
        set_flash_message(:notice, :send_instructions) if is_navigational_format?
        redirect_to :controller => "sessions", :action => "confirmation_pending" # This is changed from Devise's default
      end
    else
      respond_with(resource)
    end
  end
  
  # GET /resource/confirmation?confirmation_token=abcdef
  def show    
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      set_flash_message(:notice, :confirmed) if is_navigational_format?
      sign_in(resource_name, resource)
      if on_dashboard?
        redirect_to new_tribe_path
      else
        PersonMailer.welcome_email(current_user, current_community).deliver
        respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
      end
    else
      #check if this confirmation code matches to additional emails
      if e = Email.find_by_confirmation_token(params[:confirmation_token])
        e.confirmed_at = Time.now
        e.confirmation_token = nil
        e.save
        
        # This redirect expects that additional emails are only added when joining a community that requires it
        if on_dashboard?
          redirect_to new_tribe_path and return
        else
          PersonMailer.welcome_email(current_user, current_community).deliver
          flash[:notice] = t("layouts.notifications.additional_email_confirmed")
          redirect_to :controller => "community_memberships", :action => "new" and return
        end
      end
      
      #respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render_with_scope :new }
      # This is changed from Devise's default
      flash[:error] = t("layouts.notifications.confirmation_link_is_wrong_or_used")
      if @current_user
        if on_dashboard?
          redirect_to new_tribe_path
        else
          redirect_to :controller => "sessions", :action => "confirmation_pending"
        end
      else
        redirect_to :root
      end
    end
  end
  
end