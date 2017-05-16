require 'gigya_api'
require 'omniauth'
require 'rack/utils'

module OmniAuth
  module Strategies
    class Gigya
      include OmniAuth::Strategy

      class AuthorizationError < StandardError; end

      args [:api_key, :secret]

      def request_phase
        if env['REQUEST_METHOD'] == 'GET'
          if @configuration.use_sessions? && request.cookies[@configuration.session_cookie]
            redirect callback_url
          else            
            get_credentials
          end
        elsif (env['REQUEST_METHOD'] == 'POST') && (not request.params['username'])
          get_credentials
        else
          redirect callback_url
        end
      end

      def callback_phase
        request = Rack::Request.new env
        client = GigyaApi::Socialize.new api_key: options.api_key, secret: options.secret
        code = request.params['authCode']
        resp = client.get_token grant_type: "authorization_code", code: code
        if resp['statusCode'] == 200
          user = client.get_user_info oauth_token: resp['access_token']
          if user['statusCode'] == 200
            env['omniauth.gigya'] = user
            env['omniauth.gigya.oauth_token'] = resp['access_token']
            env['omniauth.gigya.oauth_token_expires'] = resp['expires_in']
          else
            raise AuthorizationError, "Error getting user: #{user.to_s}"
          end
        else
          raise AuthorizationError, "Error getting auth: #{resp.to_s}"
        end
        @app.call(env)
      end

      def get_credentials
        configuration = @configuration
        OmniAuth::Form.build(:title => (options[:title] || "Crowd Authentication")) do
          html '<script src="//cdn.gigya.com/JS/socialize.js?apikey=' + options.api_key. + '"></script>'
        end.to_response
      end

    end
  end
end