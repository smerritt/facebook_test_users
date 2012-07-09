require 'uri'

module FacebookTestUsers
  class User

    ATTRIBUTES = [:id, :access_token, :login_url, :email, :password]
    ATTRIBUTES.each { |attr| attr_reader attr }

    def initialize(attrs)
      ATTRIBUTES.each do |attr|
        instance_variable_set("@#{attr}", attrs[attr.to_s] || attrs[attr.to_sym])
      end
    end

    def destroy
      RestClient.delete(destroy_url)
    end

    private

    def destroy_url
      GRAPH_API_BASE + "/#{id}?access_token=#{URI.escape(access_token.to_s)}"
    end
  end
end
