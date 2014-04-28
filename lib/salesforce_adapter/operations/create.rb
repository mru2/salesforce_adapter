# Responsible for validating, running and formatting the results of a salesforce creation

module SalesforceAdapter

  # Exception : Creation failure, (still a response but no record created done)
  class SalesforceFailedCreate < StandardError
    attr_reader :code
    def initialize(code, message = nil)
      @code = code
      super(message)
    end
  end


  module Operations

    class Create < Base

      def initialize(rforce_binding, table_name, attributes)
        @table_name = table_name
        @attributes = attributes

        super(rforce_binding)
      end


      private

      def context
        "creating salesforce #{@table_name} with attributes #{Helpers.hash_to_s(@attributes)}"
      end

      def validate_request!
        raise ArgumentError.new("type must be specified for a Salesforce Create") unless @attributes[:type]
      end

      def perform
        rforce_binding.create( @table_name => Helpers.format_fields_for_create_or_update(@attributes) )
      end

      def validate_response!
        super

        # Raise exception on update failure
        if !@response[:createResponse][:result][:success]
          sf_error_code     = @response[:createResponse][:result][:errors][:statusCode]
          sf_error_message  = @response[:createResponse][:result][:errors][:message]
          raise SalesforceFailedCreate.new(sf_error_code), "#{sf_error_message}\nContext : #{context}"
        end
      end

      def format_response
        # Return the id
        @response[:createResponse][:result][:id]
      end

    end
  end
end
