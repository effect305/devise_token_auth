module DeviseTokenAuth
  class ConfirmationsController < DeviseTokenAuth::ApplicationController
    def show
      @resource = resource_class.confirm_by_code(params[:confirmation_code])

      if @resource && @resource.id
        # create client id
        @client_id  = SecureRandom.urlsafe_base64(nil, false)
        @authentication_token = SecureRandom.urlsafe_base64(nil, false)

        @resource.authentication_tokens[@client_id] = {
          token:  BCrypt::Password.create(@authentication_token),
          expiry: (Time.now + DeviseTokenAuth.token_lifespan).to_i
        }

        @resource.save!

        yield @resource if block_given?

        #redirect_to(@resource.build_auth_url(params[:redirect_url], {
        #  token:                        token,
        #  client_id:                    client_id,
        #  account_confirmation_success: true,
        #  config:                       params[:config]
        #}))
        @devise_auth_token = @authentication_token

        update_auth_header

        response.headers.merge!({'access-token' => @authentication_token})
        render json: {
            status: 'success',
            data:   resource_data
        }
        #response.set_header("access_token", token)
        #render json: {
        #    data: resource_data(resource_json: @resource.token_validation_response.merge({'access-token' => token}))
        #}
      else
        raise ActionController::RoutingError.new('Not Found')
      end
    end
  end
end
