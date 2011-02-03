module HostedGateway
  module AdminPaymentsControllerExt
    def self.included(base)
      base.class_eval do
        skip_before_filter :load_data, :only => [:process_gateway_return]
        skip_before_filter :load_amount, :only => [:process_gateway_return]

        #We need to skip this security check Rails does in order to let the payment gateway do a postback.
        skip_before_filter :verify_authenticity_token, :only => [:process_gateway_return]

        #TODO? This method is more or less copied from the normal controller - so this sort
        #of this is prone to messing up updates - maybe we could use alias_method_chain or something
        def process_gateway_return
          #TODO support multiple gateways - maybe store payment_method_id in session?
          gateway = PaymentMethod.find_by_id_and_type(ExternalGateway.parse_custom_data(params)["payment_method_id"], "ExternalGateway")
          @order, payment_made = gateway.process_response(params)

          if @order && payment_made
            #Payment successfully processed
            @order.payments.clear
            payment = @order.payments.create
            payment.started_processing
            payment.amount = params[:amount] || @order.total
            payment.payment_method = gateway
            payment.complete
            @order.save

            #The admin interface for creating an order doesn't actually step through all the different states - it remains
            #on 'cart'. In order to complete, we just need to step through the states (firing events, etc along the way) until
            #the order is "complete"
            until @order.completed?
              @order.next!
            end

            if @order.state == "complete" or @order.completed?
              flash[:notice] = I18n.t(:order_processed_successfully)
              redirect_to admin_order_url(@order)
            else
              redirect_to new_admin_order_payment_path
            end
          elsif @order.nil?
            #Order not passed through correctly
            flash[:error] = I18n.t('external_gateway.gateway_response.admin_order_missing')
            redirect_to new_admin_order_payment_path
          else
            #Error processing payment
            flash[:error] = I18n.t(:payment_processing_failed)
            redirect_to new_admin_order_payment_path and return
          end
        end
      end
    end
  end
end

