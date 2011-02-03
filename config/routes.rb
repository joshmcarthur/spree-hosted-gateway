Rails.application.routes.draw do
  # Add your extension routes here
  match '/checkout/gateway_landing' => 'checkout#process_gateway_return', :method => :post, :as => 'gateway_landing'
  match '/admin/checkout/gateway_landing' => 'admin/payments#process_gateway_return', :method => :post, :as => 'admin_gateway_landing'
end

