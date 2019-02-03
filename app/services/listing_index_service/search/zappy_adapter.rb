module ListingIndexService::Search

  class ZappyAdapter < SearchEngineAdapter

    def initialize
      @conn = Faraday.new(url: "http://127.0.0.1:8080") do |c|
         c.request  :url_encoded             # form-encode POST params
         c.response :logger                  # log requests to STDOUT
         c.response :json, :content_type => /\bjson$/
         c.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end

    def search(community_id:, search:, includes: nil)

      search_params = format_params(search)

      begin
        res = @conn.get do |req|
          req.url("/api/v1/marketplace/#{community_id}/listings", search_params)
          req.headers['Authorization'] = 'apikey key=asdfasdf'
        end.body
        Result::Success.new(parse_response(res["result"], includes))
      rescue StandardError => e
        Result::Error.new(e)
      end
    end

    private

    def format_params(original)
      defaults = {
        include_closed: false
      }
      params = {}
      params[:'page[number]'] = original[:page] if original[:page]
      params[:'page[size]'] = original[:per_page] if original[:per_page]
      params[:keywords] = original[:keywords] if original[:keywords]
      params[:include_closed] = original[:include_closed] if original[:include_closed]
      defaults.merge(params)
    end

    def listings_from_ids(ids, includes)
      # use pluck for much faster query after updating to Rails >4.1.6
      # http://collectiveidea.com/blog/archives/2015/03/05/optimizing-rails-for-memory-usage-part-3-pluck-and-database-laziness/
      # https://github.com/rails/rails/issues/17049

      Listing
        .where(id: ids) # use find_each for more efficient batch processing after updating to Rails 4.1
        .order("field(listings.id, #{ids.join ','})")
        .map {
          |l| ListingIndexService::Search::Commons.listing_hash(l, includes)
        }
    end

    def parse_response(res, includes)
      listings = res["meta"]["total"] > 0 ? listings_from_ids(res["data"], includes) : []
      {count: res["meta"]["total"],
       listings: listings}
    end
  end
end
