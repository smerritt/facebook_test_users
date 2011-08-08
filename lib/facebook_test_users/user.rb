require 'uri'

module FacebookTestUsers
  class User

    attr_accessor :id, :access_token, :login_url, :email, :password

    def initialize(attrs)
      attrs.each do |field, value|
        instance_variable_set("@#{field}", value) if respond_to?(field)
      end
    end

    def destroy
      RestClient.delete(destroy_url)
    end

    def send_friend_request_to(other)
      RestClient.post(friend_request_url_for(other),
        'access_token' => access_token.to_s)
    end

    private

    def destroy_url
      GRAPH_API_BASE + "/#{id}?access_token=#{URI.escape(access_token.to_s)}"
    end

    def friend_request_url_for(other)
      GRAPH_API_BASE + "/#{id}/friends/#{other.id}"
    end

  end
end
