module Api
  module V1
    class OrdersController < BaseController
      def create
        order = Orders::Create.call(order_params)

        if order.persisted?
          render json: OrderSerializer.new(order).as_json, status: 201
        else
          render json: { errors: order.errors.full_messages }, status: 422
        end
      end

      private

      def order_params
        params.permit(
          :restaurant_id,
          :order_type,
          :delivery_address,
          customer: [ :name, :phone ],
          items: [ :product_id, :quantity ]
        )
      end
    end
  end
end
