module Fog
  module DNS
    class Rackspace < Fog::Service

      US_ENDPOINT = 'https://dns.api.rackspacecloud.com/v1.0'
      UK_ENDPOINT = 'https://lon.dns.api.rackspacecloud.com/v1.0'

      requires :rackspace_api_key, :rackspace_username
      recognizes :rackspace_auth_url
      recognizes :rackspace_auth_token

      model_path 'fog/dns/models/rackspace'
      #model       :record
      #collection  :records
      model       :zone
      collection  :zones

      request_path 'fog/dns/requests/rackspace'
      #TODO - Import/Export, modify multiple domains
      request :callback
      request :list_domains
      request :list_domain_details
      request :modify_domain
      request :create_domains
      request :delete_domain
      request :delete_domains
      request :list_subdomains

      class Mock
      end

      class Real
        def initialize(options={})
          require 'multi_json'
          @rackspace_api_key = options[:rackspace_api_key]
          @rackspace_username = options[:rackspace_username]
          @rackspace_auth_url = options[:rackspace_auth_url]
          uri = URI.parse(options[:rackspace_dns_endpoint] || US_ENDPOINT)

          @auth_token, @account_id = *authenticate
          @path = "#{uri.path}/#{@account_id}"
          headers = { 'Content-Type' => 'application/json', 'X-Auth-Token' => @auth_token }

          @connection = Fog::Connection.new(uri.to_s, options[:persistent], { :headers => headers})
        end

        private

        def request(params)
          #TODO - Unify code with other rackspace services
          begin
            response = @connection.request(params.merge!({
              :path     => "#{@path}/#{params[:path]}"
            }))
          rescue Excon::Errors::BadRequest => error
            raise Fog::Rackspace::Errors::BadRequest.slurp error
          rescue Excon::Errors::Conflict => error
            raise Fog::Rackspace::Errors::Conflict.slurp error
          rescue Excon::Errors::NotFound => error
            raise Fog::Rackspace::Errors::NotFound.slurp error
          rescue Excon::Errors::ServiceUnavailable => error
            raise Fog::Rackspace::Errors::ServiceUnavailable.slurp error
          end
          unless response.body.empty?
            response.body = MultiJson.decode(response.body)
          end
          response
        end

        def authenticate
          options = {
            :rackspace_api_key  => @rackspace_api_key,
            :rackspace_username => @rackspace_username,
            :rackspace_auth_url => @rackspace_auth_url
          }
          credentials = Fog::Rackspace.authenticate(options)
          auth_token = credentials['X-Auth-Token']
          account_id = credentials['X-Server-Management-Url'].match(/.*\/([\d]+)$/)[1]
          [auth_token, account_id]
        end

        def array_to_query_string(arr)
          arr.collect {|k,v| "#{k}=#{v}" }.join('&')
        end
      end
    end
  end
end
