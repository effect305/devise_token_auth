module DeviseTokenAuth
  class ConfirmationsController < DeviseTokenAuth::ApplicationController
    def show
      @resource = resource_class.confirm_by_code(params[:confirmation_code])

      if @resource && @resource.id
        # create client id
        client_id  = SecureRandom.urlsafe_base64(nil, false)
        token      = SecureRandom.urlsafe_base64(nil, false)
        token_hash = BCrypt::Password.create(token)
        expiry     = (Time.now + DeviseTokenAuth.token_lifespan).to_i

        @resource.authentication_tokens[client_id] = {
          token:  token_hash,
          expiry: expiry
        }

        @resource.save!

        yield @resource if block_given?

        #redirect_to(@resource.build_auth_url(params[:redirect_url], {
        #  token:                        token,
        #  client_id:                    client_id,
        #  account_confirmation_success: true,
        #  config:                       params[:config]
        #}))
        response.set_header("access_token", token)
        render json: {
            data: resource_data(resource_json: @resource.token_validation_response.merge({'access-token' => token}))
        }
      else
        raise ActionController::RoutingError.new('Not Found')
      end
    end
  end
end
