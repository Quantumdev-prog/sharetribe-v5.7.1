module ConversationsHelper
  
  def get_message_title(listing)
    t(".#{listing.listing_type}_message_title", :title => @listing.title)
  end
  
  # Class is selected if listing type is currently selected
  def get_inbox_tab_class(tab_name)
    "inbox_tab_#{action_name.eql?(tab_name) ? 'selected' : 'unselected'}"
  end
  
end
