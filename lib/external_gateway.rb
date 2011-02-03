class ExternalGateway < PaymentMethod
  
  #We need access to routes to correctly assemble a return url
 include ActionController::UrlWriter

  #This is normally set in the Admin UI - the server in this case is where to redirect to.
  preference :server, :string
  
  #When the gateway redirects back to the return URL, it will usually include some parameters of its own 
  #indicating the status of the transaction. The following two preferences indicate which parameter keys this
  #class should look for to detect whether the payment went through successfully.
  # {status_param_key} is the params key that holds the transaction status.
  # {successful_transaction_value} is the value that indicates success - this is usually a number.
  
  preference :status_param_key, :string, :default => 'status'
  preference :successful_transaction_value, :string, :default => 'success'

  #Arbitrarily, this class is called ExternalGateway, but the extension is a whole is named 'HostedGateway', so
  #this is what we want our checkout/admin view partials to be named.
  def method_type
    "hosted_gateway"
  end

  #Process response detects the status of a payment made through an external gateway by looking 
  #for a success value (as configured in the successful_transaction_value preference), in a particular
  #parameter (as configured in the status_param_key preference). 
  #For convenience, and to validate the incoming response from the gateway somewhat, it also attempts
  #to find the order from the parameters we sent the gateway as part of the return URL and returns it
  #along with the transaction status.
  def process_response
    begin
      #Find order
      order = Order.find_by_number_and_token(params[:order], params[:order_token])

      #Check for successful response
      transaction_succeeded = params[self.preferred_status_param_key.to_sym] == self.preferred_successful_transaction_value.to_s
      return [order, transaction_succeeded]
    rescue ActiveRecord::RecordNotFound
      #Return nil and false if we couldn't find the order - this is probably bad.
      return [nil, false]
    end
  end

  #This is basically a attr_reader for server, but makes sure that it has been set.
  def get_server
    if self.preferred_server
      return self.preferred_server
    else
      raise "You need to configure a server to use an external gateway as a payment type!"
    end
  end

  #This is another attr_reader, but does a couple of necessary things to make sure we can keep track
  #of the transaction, even with multiple orders going on at different times.
  #By passing in an order, and an order token (from the session) (TODO can get the token directly from 
  #the order, and what are the consequences of this?), and a boolean to determine if the user is on an
  #admin checkout page (in which case we need to redirect to a different path), a full return url can be
  #assembled that holds key order details (number, token), and that will redirect back to the correct page
  #to complete the order.
  def get_return_url_for(order, order_token, on_admin_page = false)
    #TODO - this seems to be to be bug prone, as we are kinda relying on the gateway to 
    #see that there are params and not do something like ?(our_params)?(their params).
    #Maybe there is a neater way of doing this?
    postfix = "?order=#{order.number}&order_token=#{order_token}&payment_method_id=#{self.id}"

    if on_admin_page
      return admin_gateway_landing_url(:host => Spree::Config[:site_url]) + postfix
    else
      return gateway_landing_url(:host => Spree::Config[:site_url]) + postfix
    end
  end


  def additional_attributes
    self.stored_preferences.select { |key| !REQUIRED_ATTRIBUTES.include?(key.name) }
  end

end

