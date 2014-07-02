# Omniauth::Gigya

An Omniauth provider for Gigya OAuth functionality

## Installation

Add this line to your application's Gemfile:

    gem 'omniauth-gigya'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-gigya

## Usage

Set up the provider as you would any Omniauth provider:

    Rails.application.config.middleware.use OmniAuth::Builder do
      provider :gigya, ENV['GIGYA_API_KEY'], ENV['GIGYA_SECRET']
    end

No options are provided as of yet.  The `callback_phase` will set `env['omniauth.gigya']` as the user profile hash from Gigya in the callback controller.  It expects the authorization code from gigya in the `authCode` parameter.

    profile = env['omniauth.gigya']
    @user = User.find_by_uid profile['UID']

## TODO

Only the `callback_phase` is implemented, all other phases will throw a not yet implemented error.
