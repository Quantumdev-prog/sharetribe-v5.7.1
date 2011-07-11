class ListingsController < ApplicationController

  before_filter :save_current_path, :only => :show
  before_filter :ensure_authorized_to_view, :only => :show

  before_filter :only => [ :new, :create ] do |controller|
    controller.ensure_logged_in(["you_must_log_in_to_create_new_#{params[:type]}", "create_one_here".to_sym, sign_up_path])
  end
  
  before_filter :only => [ :edit, :update, :close ] do |controller|
    controller.ensure_logged_in "you_must_log_in_to_view_this_content"
  end
  
  before_filter :only => [ :close ] do |controller|
    controller.ensure_current_user_is_listing_author "only_listing_author_can_close_a_listing"
  end
  
  before_filter :only => [ :edit, :update ] do |controller|
    controller.ensure_current_user_is_listing_author "only_listing_author_can_edit_a_listing"
  end
  
  def index
    redirect_to root
  end
  
  def requests
    params[:listing_type] = "request"
    @to_render = {:action => :index}
    @listing_style = "listing"
    load
  end
  
  def offers
    params[:listing_type] = "offer"
    @to_render = {:action => :index}
    @listing_style = "listing"
    load
  end
  
  # Used to load listings to be shown
  # How the results are rendered depends on 
  # the type of request and if @to_render is set
  def load
    @title = params[:listing_type]
    @tag = params[:tag]
    @to_render ||= {:partial => "listings/listed_listings"}
    @listings = Listing.open.order("created_at DESC").find_with(params, @current_user, @current_community).paginate(:per_page => 15, :page => params[:page])
    @request_path = request.fullpath
    if request.xhr? && params[:page] && params[:page].to_i > 1
      render :partial => "listings/additional_listings"
    else
      render @to_render
    end
  end 
  
  def loadmap
    @title = params[:listing_type]
    @listings = Listing.open.order("created_at DESC").find_with(params, @current_user)
    @listing_style = "map"
    @to_render ||= {:partial => "listings/listings_on_map"}
    @request_path = request.fullpath
    render  @to_render
  end

  # The following two are simple dummy implementations duplicating the
  # functionality of normal listing methods.
  def requests_on_map
    params[:listing_type] = "request"
    @to_render = {:action => :index}
    @listings = Listing.open.order("created_at DESC").find_with(params, @current_user, @current_community)
    @listing_style = "map"
    load
  end

  def offers_on_map
    params[:listing_type] = "offer"
    @to_render = {:action => :index}
    @listing_style = "map"
    load
  end
  
  
  # A (stub) method for serving Listing data (with locations) as JSON through AJAX-requests.
  def serve_listing_data
    
    @listings = Listing.includes(:share_types, :location, :author).open.joins(:location).group(:id).
                order("created_at DESC").find_with(params, @current_user, @current_community)
    
    
    render :json => { :data => @listings }
  end
  
  def listing_bubble
    if params[:id] then
      @listing = Listing.find params[:id]
      render :partial => "homepage/recent_listing", :locals => {:listing => @listing}
    end 
  end
  
  def listing_all_bubbles
      @listings = Listing.includes(:share_types, :location, :author).open.joins(:location).group(:id).
                order("created_at DESC").find_with(params, @current_user, @current_community)
      @render_array = [];
      @listings.each do |listing|
        @render_array[@render_array.length] = render_to_string :partial => "homepage/recent_listing", :locals => {:listing => listing}
      end
      render :json => { :info => @render_array }
  end

  def show
    @listing.increment!(:times_viewed)
  end
  
  def new
    @listing = Listing.new
    @listing.listing_type = params[:type]
    @listing.category = params[:category] || "item"
    1.times { @listing.listing_images.build }
    if @listing.category != "rideshare"
      @listing.build_location
    else
      @listing.build_origin_loc
      @listing.build_destination_loc
    end
    respond_to do |format|
      format.html
      format.js {render :layout => false}
    end
  end
  
  def create
    @listing = @current_user.create_listing params[:listing]
    if @listing.category != "rideshare"
      @location = @listing.create_location(params[:location])
    else
      @origin_loc = @listing.create_origin_loc(params[:origin_loc])
      @destination_loc = @listing.create_destination_loc(params[:destination_loc])
    end
    if @listing.new_record?
      1.times { @listing.listing_images.build } if @listing.listing_images.empty?
      render :action => :new
    else
      path = new_request_category_path(:type => @listing.listing_type, :category => @listing.category)
      flash[:notice] = ["#{@listing.listing_type}_created_successfully", "create_new_#{@listing.listing_type}".to_sym, path]
      Delayed::Job.enqueue(ListingCreatedJob.new(@listing.id, request.host))
      redirect_to @listing
    end
  end
  
  def edit
    1.times { @listing.listing_images.build } if @listing.listing_images.empty?
  end
  
  def update
    if @listing.update_fields(params[:listing])
      @listing.location.update_attributes(params[:location]) if @listing.location
      flash[:notice] = "#{@listing.listing_type}_updated_successfully"
      redirect_to @listing
    else
      render :action => :edit
    end    
  end
  
  def close
    @listing.update_attribute(:open, false)
    notice = "#{@listing.listing_type}_closed"
    respond_to do |format|
      format.html { 
        flash[:notice] = notice
        redirect_to @listing 
      }
      format.js {
        flash.now[:notice] = notice
        render :layout => false 
      }
    end
  end
  
  #shows a random listing from current community
  def random
    open_listings_ids = Listing.open.select("id").find_with(nil, @current_user, @current_community).all
    if open_listings_ids.empty?
      redirect_to root and return
      #render :action => :index and return
    end
    random_id = open_listings_ids[Kernel.rand(open_listings_ids.length)].id
    #redirect_to listing_path(random_id)
    @listing = Listing.find_by_id(random_id)
    render :action => :show
  end
  
  def ensure_current_user_is_listing_author(error_message)
    @listing = Listing.find(params[:id])
    return if current_user?(@listing.author) || @current_user.has_admin_rights_in?(@current_community)
    flash[:error] = error_message
    redirect_to @listing and return
  end
  
  private
  
  # Ensure that only users with appropriate visibility settings can view the listing
  def ensure_authorized_to_view
    @listing = Listing.find(params[:id])
    if @current_user
      unless @listing.visible_to?(@current_user, @current_community)
        flash[:error] = "you_are_not_authorized_to_view_this_content"
        redirect_to root and return
      end
    else
      unless @listing.visibility.eql?("everybody")
        session[:return_to] = request.fullpath
        flash[:warning] = "you_must_log_in_to_view_this_content"
        redirect_to new_session_path and return
      end
    end
  end

end
