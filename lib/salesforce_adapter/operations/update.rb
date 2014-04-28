# Responsible for validating, running and formatting the results of a salesforce update

module SalesforceAdapter

  # Exception : Update failure, (still a response but no update done)
  class SalesforceFailedUpdate < StandardError
    attr_reader :code
    def initialize(code, message = nil)
      @code = code
      super(message)
    end
  end


  module Operations

    class Update < Base

      def initialize(rforce_binding, table_name, attributes)
        @table_name = table_name
        @attributes = attributes

        super(rforce_binding)
      end


      private

      def context
        "updating salesforce #{@table_name} with attributes #{Helpers.hash_to_s(@attributes)}"
      end

      def validate_request!
        raise ArgumentError.new("Id must be specified for a Salesforce Update")   unless @attributes[:Id]
        raise ArgumentError.new("type must be specified for a Salesforce Update") unless @attributes[:type]
      end

      def perform
        rforce_binding.update( @table_name => Helpers.format_fields_for_create_or_update(@attributes) )
      end

      def validate_response!
        super

        # Raise exception on update failure
        if !@response[:updateResponse][:result][:success]
          sf_error_code     = @response[:updateResponse][:result][:errors][:statusCode]
          sf_error_message  = @response[:updateResponse][:result][:errors][:message]
          raise SalesforceFailedUpdate.new(sf_error_code), "#{sf_error_message}\nContext : #{context}"
        end
      end

      def format_response
        # Return the id
        @response[:updateResponse][:result][:id]
      end

    end

  end
end
