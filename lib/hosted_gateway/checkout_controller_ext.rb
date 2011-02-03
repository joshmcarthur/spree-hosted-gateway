module HostedGateway
  module CheckoutControllerExt
    def self.included(base)
      self.class_eval do
        #TODO? This method is more or less copied from the normal controller - so this sort
        #of this is prone to messing up updates - maybe we could use alias_method_chain or something?
        
        def process_gateway_return
          gateway = PaymentMethod.find_by_id_and_type(params[:payment_method_id], "ExternalGateway")
          @order, payment_made = gateway.process_response(params)

          if @order && payment_made
            #Payment successfully processed
            checkout = @order.checkout
            checkout.payments.clear
            payment = checkout.payments.create
            payment.amount = params[:amount] || @order.total
            payment.payment_method = gateway
            checkout.save

            if @order.next
              state_callback(:after)
            end

            if @order.state == "complete" or @order.completed?
              flash[:notice] = I18n.t(:order_processed_successfully)
              flash[:commerce_tracking] = "nothing special"
              redirect_to completion_route
            else
              redirect_to checkout_state_path(@order.state)
            end
          elsif @order.nil?
            #Order not passed through correctly
            flash[:error] = I18n.t(:order_missing)
            redirect_to checkout_path
          else
            #Error processing payment
            flash[:error] = I18n.t(:payment_processing_failed)
            redirect_to checkout_state_path(@order.state) and return
          end
        end
      end
    end
  end
end

