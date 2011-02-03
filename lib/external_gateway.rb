class ExternalGateway < PaymentMethod
 include ActionController::UrlWriter

  preference :server, :string
  preference :returned_status_param_key, :string, :default => 'status'
  preference :returned_status_success_value, :string, :default => 'success'

  REQUIRED_ATTRIBUTES = ["server", "return_url"]

  def method_type
    "hosted_gateway"
  end

  def process_response
    begin
      #Find order
      order = Order.find_by_number_and_token(params[:order], params[:order_token])

      #Check for successful response
      transaction_succeeded = params[self.preferred_returned_status_param_key.to_sym] == self.preferred_returned_status_success_value.to_s
      return [order, transaction_succeeded]
    rescue ActiveRecord::RecordNotFound
      return [nil, false]
    end
  end

  def get_server
    if self.preferred_server
      return self.preferred_server
    else
      raise "You need to configure a server to use an external gateway as a payment type!"
    end
  end

  def get_return_url_for(order, order_token, on_admin_page = false)
    postfix = "?order=#{order.number}&order_token=#{order_token}&payment_method_id=#{self.id}"

    if on_admin_page
      return admin_gateway_landing_url(:host => Spree::Config[:site_url]) + postfix
    else
      return gateway_landing_url(:host => Spree::Config[:site_url]) + postfix
    end
  end

  def get_amount_for(order)
    return order.total
  end

  def additional_attributes
    self.stored_preferences.select { |key| !REQUIRED_ATTRIBUTES.include?(key.name) }
  end

end

