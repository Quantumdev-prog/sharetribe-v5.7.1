class NewsItemsController < ApplicationController
  
  layout "layouts/infos"
  
  before_filter :only => [ :create, :destroy ] do |controller|
    controller.ensure_logged_in "you_must_log_in_to_view_this_content"
  end
  
  def index
    redirect_to about_infos_path and return unless @current_community.news_enabled
    params[:page] = 1 unless request.xhr?
    @news_items = @current_community.news_items.order("created_at DESC").paginate(:per_page => 10, :page => params[:page])
    if @current_community.all_users_can_add_news?
      @news_item = NewsItem.new 
      @path = news_items_path
    end
    request.xhr? ? (render :partial => "additional_news_items") : render
  end
  
  def create
    redirect_to root and return unless @current_community.all_users_can_add_news?
    @news_item = NewsItem.new(params[:news_item])
    if @news_item.save
      flash[:notice] = "news_item_created"
      redirect_to news_items_path
    else
      flash[:error] = "news_item_creation_failed"
      redirect_to news_items_path(:news_form => true)
    end
  end
  
  def destroy
    news_item = NewsItem.find(params[:id])
    redirect_to news_items_path and return unless current_user?(news_item.author)
    news_item.destroy
    flash[:notice] = "news_item_deleted"
    redirect_to news_items_path
  end
  
end