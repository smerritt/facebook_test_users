require 'cgi'
require 'restclient'

# A million thanks to Filip Tepper for https://github.com/filiptepper/facebook-oauth-example

module FacebookTestUsers
  class AccessToken

    OAUTH_BASE = 'https://graph.facebook.com/oauth/access_token'
    
    def self.get(app_id, app_secret, oauth_base=OAUTH_BASE)
      response = RestClient.get(
        oauth_base,
        :params => {
          'client_id'     => app_id,
          'client_secret' => app_secret,
          'grant_type'    => 'client_credentials'   # FB magic string
        })

      extract_access_token(response)
   end

    private

    def self.extract_access_token(response_body)
      JSON.parse(response_body)["access_token"]
    end

  end
end
