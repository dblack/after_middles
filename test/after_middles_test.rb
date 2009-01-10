require 'test_helper'

class MyRackApp
  def call(env)
    status, headers, response = @app.call(env)
    response.body.gsub!(/Dave/, "David")
    response.to_a
  end
end

class OtherRackApp
  def call(env)
    status, headers, response = @app.call(env)
    response.body.gsub!(/item/, "thing")
    response.body.gsub!(/Dave/, "nothing")
    response.to_a
  end
end
 
class StatusChanger
  def call(env)
    status, headers, response = @app.call(env)
    if response.body =~ /SECRET/
      response.status = "404 Not Found"
    end
    response.to_a
  end
end

class AftersController < ApplicationController
  after_middle MyRackApp
  after_middle OtherRackApp, :only => "show"
  after_middle StatusChanger
  def index
    render :text => "Dave is cool, isn't Dave?"
  end
  def show
    render :text => "This is an item or something."
  end
  def hidden
    render :text => "This is TOP SECRET."
  end
end

ActionController::Routing::Routes.draw do |map|
  map.connect 'afters/index',
    :controller => "afters"
  map.connect 'afters/show/:id',
    :controller => "afters", :action => "show"
  map.connect 'afters/hidden',
    :controller => "afters", :action => "hidden"
end

class AfterMiddlesTest < ActiveSupport::TestCase
  fixtures :all

  def setup
  end

  def test_gsub_rack_app
    get("afters/index")
    assert_equal("David is cool, isn't David?",
      response.body)
  end

  def test_only_parameter
    get("afters/show/1")
    assert_equal("This is an thing or something.",
      response.body)
  end

  def test_status_changer
    get("afters/hidden")
    assert_equal(404, response.status)
  end
end
