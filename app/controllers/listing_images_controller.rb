class ListingImagesController < ApplicationController
  
  # Skip auth token check as current jQuery doesn't provide it automatically
  skip_before_filter :verify_authenticity_token, :only => [:destroy]

  before_filter :fetch_image, :only => [:destroy]
  before_filter :"listing_image_authorized?", :only => [:destroy]

  before_filter :fetch_listing, :only => [:add_from_file]
  before_filter :"listing_authorized?", :only => [:add_from_file]

  skip_filter :dashboard_only
  
  def destroy
    @listing_image_id = @listing_image.id.to_s
    if @listing_image.destroy
      render nothing: true, status: 204
    else
      render json: {:errors => listing_image.errors.full_messages}, status: 400
    end
  end

  # Create new listing
  def create_from_file
    listing_image_params = params[:listing_image].merge(author: @current_user)
    new_image(listing_image_params)
  end

  # Add photo to existing listing
  def add_from_file
    listing_id = params[:listing_id]

    if listing_id
      ListingImage.destroy_all(listing_id: listing_id)
    end

    listing_image_params = params[:listing_image].merge(author: @current_user).merge(listing_id: listing_id)
    new_image(listing_image_params)
  end

  def new_image(params)
    listing_image = ListingImage.new(params)

    if listing_image.save
      render json: {
        id: listing_image.id, 
        removeUrl: listing_image_path(listing_image),
        processedPollingUrl: processed_images_listing_image_path(listing_image)
      }, status: 202
    else
      render json: {:errors => listing_image.errors.full_messages}, status: 400
    end
  end

  def processed_images
    listing_image = ListingImage.find_by_id_and_author_id(params[:id], @current_user.id)

    if !listing_image
      render nothing: true, status: 404
    elsif listing_image.image_processing
      render json: {processing: true}, status: 200
    else
      render json: {processing: false, thumb: listing_image.image.url(:thumb)}, status: 200
    end
  end

  # def create_from_url
  #   image_url = params[:listing_image][:image_url]
  #   listing_id = params[:listing_image][:listing_id]
  #   listing_image = ListingImage.new(image: image_url, author: @current_user)

  #   if listing_image.save
  #     render json: {listing_image_id: listing_image.id, filename: listing_image.image_file_name}, status: 201
  #   else
  #     render json: {:errors => listing_image.errors.full_messages}, status: 400
  #   end
  # end

  def fetch_image
    @listing_image = ListingImage.find_by_id(params[:id])
  end

  def fetch_listing
    @listing = Listing.find_by_id(params[:listing_id])
  end

  def listing_image_authorized?
    @listing_image.authorized?(@current_user)
  end

  def listing_authorized?
    @listing.author == @current_user
  end
end
