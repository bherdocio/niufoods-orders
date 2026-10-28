module Api
  module V1
    class BaseController < ActionController::API
      wrap_parameters false

      rescue_from ActionDispatch::Http::Parameters::ParseError do
        render json: { errors: [ "JSON inválido" ] }, status: 400
      end
    end
  end
end
