module Orders
  class DashboardFilter
    attr_reader :status, :restaurant_id, :from, :to

    def initialize(params)
      @status = params[:status].presence_in(Order.dispatch_statuses.keys)
      @restaurant_id = params[:restaurant_id].presence
      @from = parse_date(params[:from])
      @to = parse_date(params[:to])
      @from, @to = @to, @from if @from && @to && @from > @to
    end

    def base_scope
      scope = Order.all
      scope = scope.where(restaurant_id: restaurant_id) if restaurant_id
      scope = scope.where(created_at: from.in_time_zone.beginning_of_day..) if from
      scope = scope.where(created_at: ..to.in_time_zone.end_of_day) if to
      scope
    end

    def orders_scope
      status ? base_scope.where(dispatch_status: status) : base_scope
    end

    def restaurants
      scope = Restaurant.order(:name)
      restaurant_id ? scope.where(id: restaurant_id) : scope
    end

    private

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
  end
end
