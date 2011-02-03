module HostedGateway
  module AdminPaymentsControllerExt
    def self.included(base)
      base.class_eval do
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
              redirect_to admin_order_url(@order)
            else
              redirect_to new_object_path
            end
          elsif @order.nil?
            #Order not passed through correctly
            flash[:error] = I18n.t(:order_missing)
            redirect_to new_object_path
          else
            #Error processing payment
            flash[:error] = I18n.t(:payment_processing_failed)
            redirect_to new_object_path and return
          end
        end
      end
    end
  end
end

