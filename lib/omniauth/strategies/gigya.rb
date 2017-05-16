# frozen_string_literal: true

require 'gigya_api'
require 'omniauth'
require 'rack/utils'

# Defines the Gigya auth strategy.
module OmniAuth
  module Strategies
    class Gigya
      include OmniAuth::Strategy

      class AuthorizationError < StandardError; end

      args [:api_key, :secret]
      option :api_key, nil
      option :secret, nil
      option :title, nil
      option :screen_set, nil
      option :mobile_screen_set, nil
      option :start_screen

      def request_phase
        if env['REQUEST_METHOD'] == 'GET'
          get_credentials
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
        api_key = options.api_key
        login_js = generate_login_js
        OmniAuth::PageWithoutForm.build(title: (options.title || "Gigya Authentication")) do
          html '<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>'
          html '<script type="text/javascript" src="//cdn.gigya.com/JS/socialize.js?apikey=' + api_key + '"></script>'
          html '<div id="gigya-screenset-container"></div>'
          html '<script type="text/javascript">' + login_js + '</script>'
        end.to_response
      end

      def generate_login_js
        [
          '(function() {',
          'var gigya = null;',
          'var loginDiv = document.querySelector("#gigya-screenset-container");',
          'var Callbacks = {};',
          'var Commands = {};',
          'Callbacks.onLogin = function(data) {',
          '  if (data.eventName == "login") {',
          '    console.log(data);',
          '  }',
          '};',
          'Callbacks.onGetUserInfo = function(data) {',
          '  if (data.status == "OK" && !!data.user && !!data.user.UID) {',
          '    console.log(data);',
          '  }',
          '  else {',
          '    Commands.showLogin();',
          '  }',
          '};',
          'Callbacks.onLoad = function() {',
          '  var deferGigya = $.Deferred();',
          '  var interval = setInterval(function() {',
          '    if (!!window.gigya) {',
          '      deferGigya.resolve(window.gigya);',
          '      clearInterval(interval);',
          '    }',
          '  }, 100);',
          '  $.when(deferGigya).done(function(promisedGigya) {',
          '    gigya = promisedGigya;',
          '    Commands.init();',
          '  }).promise();',
          '};',
          'Commands.init = function() {',
          '  gigya.accounts.addEventHandlers({',
          '    onLogin: Callbacks.onLogin',
          '  });',
          '  gigya.services.socialize.getUserInfo({',
          '    callback: Callbacks.onGetUserInfo',
          '  });',
          '};',
          'Commands.showLogin = function() {',
          '  if (!!loginDiv) {',
          '    gigya.accounts.showScreenSet({',
          '      screenSet: "' + options.screen_set + '",',
          '      mobileScreenSet: "' + options.mobile_screen_set + '",',
          '      startScreen: "' + options.start_screen + '",',
          '      containerID: "gigya-screenset-container"',
          '    });',
          '  }',
          '};',
          '$(document).ready(Callbacks.onLoad);',
          '})();',
        ].join("\n")
      end
    end
  end
end
