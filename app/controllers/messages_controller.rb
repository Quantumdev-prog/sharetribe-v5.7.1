class MessagesController < ApplicationController
  
  before_filter do |controller|
    controller.ensure_logged_in "you_must_log_in_to_send_a_message"
    controller.ensure_authorized "you_are_not_authorized_to_do_this"
  end
  
  def create
    @message = Message.new(params[:message])
    if @message.save 
      flash[:message_notice] = "reply_sent"
      PersonMailer.new_message_notification(@message, request.host).deliver
    else
      flash[:error] = "reply_cannot_be_empty"
    end  
    respond_to do |format|
      format.html { redirect_to single_conversation_path(:conversation_type => "received", :person_id => @current_user.id, :id => params[:message][:conversation_id]) }
      format.js { render :layout => false }
    end
  end
  
end
