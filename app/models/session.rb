require 'json'

class Session

  attr_accessor :username
  attr_writer   :password
  attr_accessor :app_name
  attr_writer   :app_password
  attr_reader   :headers
  attr_reader   :person_id
  
  @@kassi_cookie = nil # a cookie stored for a general App-only session for Kassi
  @@session_uri = "#{APP_CONFIG.ssl_asi_url}/session"
  
  # Creates a session and logs it in to Aalto Social Interface (ASI)
  def self.create(params={})
    session = Session.new(params)
    # begin 
    session.login
    # rescue RestClient::Request::Unauthorized
    #   return nil
    # end
    return session
  end
  
  def initialize(params={})
    self.username = params[:username]
    self.password = params[:password]
    self.app_name = params[:app_name]
    self.app_password = params[:app_password]
  end
  
  #Logs in to Aalto Social Interface (ASI)
  def login(params={})
    @headers = {}
    params = {:session => {}}
    
    # if both username and password given as parameters or instance variables
    if ((@username && @password) || (params[:username] && params[:password]))
      params[:session][:username] = params[:username] || @username
      params[:session][:password] = params[:password] || @password
    end
    params[:session][:app_name] = @app_name || APP_CONFIG.asi_app_name
    params[:session][:app_password] = @app_password || APP_CONFIG.asi_app_password

    resp = RestHelper.make_request(:post, @@session_uri, params , nil, true)

    @headers["Cookie"] = resp[1].headers[:set_cookie].to_s
    @person_id = resp[0]["entry"]["user_id"]
  end
  
  # A class method for destroying a session based on cookie
  def self.destroy(cookie)
    deleting_headers = {"Cookie" => cookie}
    resp = RestHelper.make_request(:delete, @@session_uri, deleting_headers, nil, true)
  end
  
  def destroy
    Session.destroy(@headers["Cookie"])
  end
  
  #Use only for session containing a user (NO app-only session)
  def self.get_by_cookie(cookie)
    new_session = Session.new
    new_session.cookie = cookie

    return nil unless new_session.set_person_id()   
    return new_session
  end
  
  #a general app-only session cookie that maintains an open session to ASI for Kassi
  def self.kassiCookie
    if @@kassi_cookie.nil?
      @@kassi_cookie = Session.create.cookie
    end
    return @@kassi_cookie
  end
  
  #this method can be called, if kassiCookie is not valid anymore
  def self.updateKassiCookie
    @@kassi_cookie = Session.create.cookie
  end
  
  # Posts a GET request to ASI for this session
  def check
    begin
      return RestHelper.get(@@session_uri, @headers)
    rescue RestClient::ResourceNotFound => e
      return nil
    end
  end
  
  def cookie
    @headers["Cookie"]
  end
  
  def cookie=(cookie)
    @headers ||= {}
    @headers["Cookie"] = cookie
  end
  
  def set_person_id
    info = self.check
    return nil if (info.nil? || info["entry"].nil?)
    @person_id =  info["entry"]["user_id"]
    return @person_id
  end
end
