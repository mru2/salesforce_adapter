# Wrapper around the rforce binding, responsible to guarantee it is logged in

module SalesforceAdapter

  class RforceBinding

    def initialize(url, login, password)
      @url      = url
      @login    = login
      @password = password

      @rforce = RForce::Binding.new(@url)
    end


    # Attempts to login to salesforce
    def login
      @rforce.login( @login , @password )
    end


    # Is it currently logged in?
    def logged_in?
      # An unlogged rforce binding has a session_id defined as nil
      # Does not handle session expiration however
      !!@rforce.instance_variable_get(:@session_id)
    end


    # Delegate all these methods to the rforce binding
    [:query, :create, :update, :call_remote].each do |method_name|

      define_method method_name do |*args, &block|

        Helpers.handle_timeout(:max_tries => 4, :sleep_between_tries => 2) do

          login unless logged_in?
          @rforce.send method_name, *args, &block

        end

      end

    end

  end

end
