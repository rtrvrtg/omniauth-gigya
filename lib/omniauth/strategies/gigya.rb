# frozen_string_literal: true

require 'gigya_api'
require 'omniauth'
require 'rack/utils'
require 'openssl'
require 'base64'

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

      # Request phase.
      # We want to show the form unless we have a valid POST.
      def request_phase
        if env['REQUEST_METHOD'] == 'GET'
          get_credentials
        elsif (env['REQUEST_METHOD'] == 'POST') && (not request.params['UID'])
          get_credentials
        else
          redirect callback_url
        end
      end

      # Accept the request and validate the UID signature.
      # This differs from the upstream implementation which uses OAuth flow.
      def callback_phase
        request = Rack::Request.new(env)
        user = request.params
        client = GigyaApi::Socialize.new(api_key: options.api_key, secret: options.secret)
        code = request.params['authCode']
        resp = client.get_token(grant_type: 'authorization_code', code: code)
        if user.UID && user.UIDSignature && user.timestamp
          validated = validate_sig(user.UIDSignature, user, options.secret)
          if validated
            env['omniauth.gigya'] = user
          else
            raise AuthorizationError, "Error getting user: #{user.to_s}"
          end
        else
          raise AuthorizationError, "Error getting auth: #{resp.to_s}"
        end
        @app.call(env)
      end

      private

      # Displays a page to load the Gigya JS.
      def get_credentials
        api_key = options.api_key
        login_js = generate_login_js
        OmniAuth::PageWithoutForm.build(title: (options.title || "Gigya Authentication")) do
          html '<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>'
          html '<script type="text/javascript" src="https://cdn.gigya.com/JS/socialize.js?apikey=' + api_key + '"></script>'
          html '<div id="gigya-screenset-container"></div>'
          html '<script type="text/javascript">' + login_js + '</script>'
        end.to_response
      end

      # Generates JS to load the current user, or show a login form.
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
          '      authFlow: "redirect",',
          '      redirectUrl: "' + callback_url + '",',
          '    });',
          '  }',
          '};',
          '$(document).ready(Callbacks.onLoad);',
          '})();',
        ].join("\n")
      end

      # Validate a user signature.
      def validate_sig(signature, user, secret)
        signature == construct_sig(user, secret)
      end

      # Construct a user signature for validation.
      def construct_sig(user, secret)
        Base64.encode64(
          OpenSSL::HMAC.digest(
            OpenSSL::Digest.new('sha256'),
            Base64.decode64(secret),
            (user['timestamp'] + '_' + user['UID']).force_encoding("utf-8")
          )
        ).strip()
      end
    end
  end
end
