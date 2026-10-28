module Stores
  class OrdersController < ActionController::API
    wrap_parameters false

    def create
      restaurant = Restaurant.find_by(code: params[:code])
      return render(json: { error: "Tienda no encontrada" }, status: 404) unless restaurant
      return render(json: { error: "Tienda no disponible" }, status: 503) if simulate_failure?
      return render(json: { error: "Payload sin id de orden" }, status: 422) if params[:id].blank?

      Rails.logger.info("[Tienda #{restaurant.code}] Orden ##{params[:id]} recibida (Idempotency-Key: #{request.headers['Idempotency-Key']})")
      render json: { received: true, store: restaurant.code, order_id: params[:id] }, status: 200
    end

    private

    def simulate_failure?
      rand < ENV.fetch("STORE_FAILURE_RATE", "0").to_f
    end
  end
end
