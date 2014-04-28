# Base class for performing rforce operations
# Template for formatting input, performing operation and validating results
# Implementation details defined in subclasses

# Responsible for validating, running and formatting the results of a query

module SalesforceAdapter

  # Exception : Fault from the API, no results returned. The error code has its accessor : :code
  class SalesforceApiFault  < StandardError
    attr_reader :code
    def initialize(code, message = nil)
      @code = code
      super(message)
    end
  end


  module Operations

    class Base

      attr_reader :rforce_binding


      def initialize(rforce_binding)
        @rforce_binding = rforce_binding
      end


      def run
        validate_request!

        Helpers.handle_timeout(:max_tries => 4, :sleep_between_tries => 5) do
          @response = perform
        end

        validate_response!

        format_response
      end


      private

      def context
        "No context given"
      end

      def validate_request!
        # nothing by default...
      end

      def perform!
        raise NotImplementedError.new("Must be defined in subclass")
      end

      def validate_response!
        # Check for API errors and raise them
        if @response[:Fault]

          fault_code    = @response[:Fault][:faultcode] # "sf:MALFORMED_QUERY"
          fault_details = @response[:Fault][:faultstring]

          message = "Salesforce API Fault : #{fault_details}.\nContext : #{context}"

          raise SalesforceApiFault.new(fault_code), message
        end

      end

      def format_response
        # Nothing by default
        @response
      end

    end

  end
end
