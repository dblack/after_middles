# AfterMiddles
#
# Experimental plugin by David A. Black
#
# January 10, 2008
#
# Use at your own risk. 
#
# Usage:

#   class MyRackApp
#     def call(env)
#       s,h,r = @app.call(env)  # @app is there already
#       do_stuff_blah_blah
#       [s,h,r]   # or r.to_a if appropriate
#     end
#   end
#
#   class ItemsController
#     after_middle MyRackApp, :only => :show
#   end

module ActionController
  class Base
    def add_after_middle(klass)
      rclass = Class.new(klass) do
        pim = klass.private_instance_methods(false)
        unless pim.any? {|m| m.to_s == "initialize" }
          def initialize(app)
            @app = app
          end
        end
      end

      after_middles.unshift rclass
    end


  # The Rack apps are stored in an array, which
  # is then massaged into a MiddlewareStack just
  # before the response is sent. 
    def after_middles
      @after_middles ||= []
    end

    def prepare_after_stack
      @after_stack ||= MiddlewareStack.new do |middleware|
        after_middles.each do |am|
          middleware.use(am)
        end
      end
      @app = @after_stack.build(lambda { |env| _call(env) })
    end

    def _call(env)
      response.to_a
    end

    def send_response_with_after_middles
      prepare_after_stack
      status, headers, response = @app.call(request.env)
    # The to_a operation on the response introduces
    # an empty content header. This is a stop-gap way
    # of dealing with it. 
      h = response.headers 
      h.delete("Content-Length") if
        h.has_key?("Content-Length") &&
        h["Content-Length"] != response.body.size
      response.headers.merge!(headers)
    # This may or may not be necessary, depending on
    # whether someone has changed the status in the response
    # object or piggy-backed a new status in the Rack
    # response array. 
      response.status = status
      send_response_without_after_middles
    end

    alias_method_chain :send_response, :after_middles

    def self.after_middle(app,*args)
      before_filter(*args) do |c|
        c.add_after_middle(app)
      end
    end
  end
end

