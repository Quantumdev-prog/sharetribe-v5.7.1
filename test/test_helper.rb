ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

begin
  require 'redgreen'
rescue Exception => e
  #Redgreen is copletely optional so no problem if not found :)
end

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  ##
  # returns a test person and a session-cookie where he's logged in. 
  # If the person doesn't exist already, creates him.
  
  def get_test_person_and_session(username="kassi_testperson1")
    session = nil
    test_person = nil
    
    #frist try loggin in to cos
    begin
      session = Session.create({:username => username, :password => "testi" })
      #try to find in kassi database
      test_person = Person.find(session.person_id)

    rescue RestClient::Request::Unauthorized => e
      #if not found, create completely new
      session = Session.create
      test_person = Person.create({ :username => username, 
                      :password => "testi", 
                      :email => "#{username}@example.com"},
                       session.headers["Cookie"])
                       
    rescue ActiveRecord::RecordNotFound  => e
      test_person = Person.add_to_kassi_db(session.person_id)
    end
    return [test_person, session]
  end
  
  def uploaded_file(filename, content_type)
    t = Tempfile.new(filename)
    t.binmode
    path = RAILS_ROOT + "/test/fixtures/" + filename
    FileUtils.copy_file(path, t.path)
    (class << t; self; end).class_eval do
      alias local_path path
      define_method(:original_filename) {filename}
      define_method(:content_type) {content_type}
    end
    return t
  end
  
  def assert_redirect_when_not_logged_in
    assert_response :found
    assert_redirected_to new_session_path
    assert_equal flash[:warning], :you_must_login_to_do_this
  end
  
  def submit_with_person(action, parameters = nil, parameter_type = :listing, person_type = :author_id, method = :post, username = "kassi_testperson1")
    current_user, session = get_test_person_and_session(username)
    case (method)
    when :post
      parameters[parameter_type].merge!({person_type => current_user.id }) if person_type
      post action, parameters, {:person_id => current_user.id, :cookie => session.cookie}
    when :put
      parameters[parameter_type].merge!({person_type => current_user.id }) if person_type 
      put action, parameters, {:person_id => current_user.id, :cookie => session.cookie}
    when :get
      get action, parameters, {:person_id => current_user.id, :cookie => session.cookie}
    when :delete
      delete action, parameters, {:person_id => current_user.id, :cookie => session.cookie}    
    end  
    session.destroy
  end
  
  def assert_does_not_exist(id, model)
    assert_raise(ActiveRecord::RecordNotFound) {
      case model
      when "item"
        Item.find(id)
      end  
    }
  end
      
end

# This module wraps convenience methods used to
# make integration tests clearer.
# module IntegrationTestHelpers
#   
#   def login(username, password)
#     post "/session", { :username => username, :password => password}
#     assert_response :found
#   end
#   
#   def logout
#     delete "/session"
#     assert_response :found
#   end
#   
#   def request_friend(friend)
#     post "/people/#{friend.id}/friends"
#     assert_response :success
#     assert_equal :friend_requested, flash[:notice]
#   end
#   
#   def remove_friend(person, friend)
#     delete "/people/#{person.id}/friends/#{friend.id}"
#     assert_response :success
#     assert_equal :friend_removed, flash[:notice]
#   end
#   
#   def join_group
#     
#   end
#   
#   def leave_group
#     
#   end
#   
#   # Creates a new listing, a new item and a new favor
#   # with the given visibility, and returns their
#   # ids in a hash.
#   def create_content_items(visibility)
#     content_items = {}
#     
#     post "/listings", { get_listing_params(visibility) }
#     assert ! assigns(:listing).new_record?
#     content_items[:listing] = assigns(:listing)
#     
#     
#     
#   end
#   
#   # Tries to view the created content items, asserts
#   # the viewing result given as a parameter
#   def view_content_items(content_items, is_visible)
#     get listing_path(content_items[:listing])
#     if is_visible
#     
#     else
#       if session[:id]
#         
#       else
#         assert_redirected_to new_session_path
#       end  
#     end
#     
#     get item_path(content_items[:item].title)
#     if is_visible
#     
#     else
#       
#     end
#     
#     get favor_path(content_items[:favor].title)
#     if is_visible
#     
#     else
#       
#     end    
#   end
#   
#   private
#   
#   def get_listing_params(visibility)
#     { 
#       :listing => {
#         :category => "sell",
#         :title => "Test title",
#         :content => "Test content.",
#         :good_thru => DateTime.now+(2),
#         :times_viewed => 32,
#         :status => "open",
#         :language_fi => 1
#       }
#     }
#   end
#   
#   def get_item_params(visibility_params)
#     
#   end
#   
# end  