require 'gigya_api'
require 'omniauth'
require 'rack/utils'

module OmniAuth
  module Strategies
    class Gigya
      include OmniAuth::Strategy

      class AuthorizationError < StandardError; end

      args [:api_key, :secret]

      def callback_phase
        request = Rack::Request.new env
        client = GigyaApi::Socialize.new api_key: options.api_key, secret: options.secret
        code = request.params['authCode']
        resp = client.get_token grant_type: "authorization_code", code: code
        if resp['statusCode'] == 200
          token = resp['access_token']
          user = client.get_user_info oauth_token: token
          unless user['statusCode'] == 200
            return user
          else
            raise AuthorizationError, "Error getting user: #{resp.to_s}"
          end
        else
          raise AuthorizationError, "Error getting auth: #{resp.to_s}"
        end
        super
      end

    end
  end
end