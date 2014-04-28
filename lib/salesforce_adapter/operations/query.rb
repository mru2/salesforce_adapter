# Responsible for validating, running and formatting the results of a query

module SalesforceAdapter
  module Operations

    class Query < Base

      def initialize(rforce_binding, query_string)
        @query_string = query_string

        super(rforce_binding)
      end


      private

      def context
        "querying salesforce with : #{@query_string}"
      end

      def perform
        rforce_binding.query(:queryString => @query_string)
      end

      def format_response
        # If no results, return an empty array
        return [] if @response[:queryResponse][:result][:size] == "0"

        # Otherwise return an array of the results (can be empty, or contain only one result)
        records = @response[:queryResponse][:result][:records]

        if records.is_a?(Array)
          return records
        else
          return [records].compact # if nil => returning an empty array
        end
      end


    end

  end
end
