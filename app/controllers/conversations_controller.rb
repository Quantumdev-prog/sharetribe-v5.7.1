class ConversationsController < ApplicationController

  before_filter :only => [ :new, :create ] do |controller|
    controller.ensure_logged_in "you_must_log_in_to_send_a_message"
  end
  
  before_filter :except => [ :new, :create ] do |controller|
    controller.ensure_logged_in "you_must_log_in_to_view_your_inbox"
    controller.ensure_authorized "you_are_not_authorized_to_view_this_content"
  end
  
  before_filter :save_current_inbox_path, :only => [ :received, :sent, :show ]
  before_filter :ensure_listing_is_open, :only => [ :new, :create ]
  before_filter :ensure_listing_author_is_not_current_user, :only => [ :new, :create ]
  
  def index
    redirect_to received_person_messages_path(:person_id => @current_user.id)
  end
  
  def received
    @conversations = @current_user.messages_that_are("received").paginate(:per_page => 15, :page => params[:page])
    request.xhr? ? (render :partial => "additional_messages") : (render :action => :index)
  end
  
  def sent
    @conversations = @current_user.messages_that_are("sent").paginate(:per_page => 15, :page => params[:page])
    request.xhr? ? (render :partial => "additional_messages") : (render :action => :index)
  end
  
  def show
    @conversation = Conversation.find(params[:id])
    @current_user.read(@conversation) unless @conversation.read_by?(@current_user)
  end

  def new
    @conversation = Conversation.new
    @conversation.messages.build
    @conversation.participants.build
    render :action => :new, :layout => "application"
  end
  
  def create
    @conversation = Conversation.new(params[:conversation])
    if @conversation.save
      flash[:notice] = "#{@conversation.listing.category}_#{@conversation.listing.listing_type}_message_sent"
      @conversation.send_email_to_participants(request) 
      redirect_to (session[:return_to_content] || root)
    else
      render :action => :new
    end  
  end
  
  def accept
    change_status("accepted")
  end
  
  def reject
    change_status("rejected")
  end
  
  private
  
  # Saves current path so that the user can be
  # redirected back to that path when needed.
  def save_current_inbox_path
    session[:return_to_inbox_content] = request.fullpath
  end
  
  def change_status(status)
    @conversation = Conversation.find(params[:id])
    @conversation.update_attribute(:status, status)
    @conversation.participations.find_by_person_id(@current_user.id).update_attribute(:is_read, true)
    flash.now[:notice] = "#{@conversation.discussion_type}_#{status}"
    respond_to do |format|
      format.html { render :action => :show }
      format.js { render :layout => false }
    end
  end
  
  def ensure_listing_is_open
    @listing = params[:conversation] ? Listing.find(params[:conversation][:listing_id]) : Listing.find(params[:id])
    if @listing.closed?
      flash[:error] = "you_cannot_reply_to_a_closed_#{@listing.listing_type}"
      redirect_to (session[:return_to_content] || root)
    end
  end
  
  def ensure_listing_author_is_not_current_user
    if current_user?(@listing.author)
      flash[:error] = "you_cannot_reply_to_your_own_#{@listing.listing_type}"
      redirect_to (session[:return_to_content] || root)
    end  
  end

end
