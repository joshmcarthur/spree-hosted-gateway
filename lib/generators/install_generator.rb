module HostedGateway
  module Generators
    class InstallGenerator < Rails::Generators::Base

      def add_javascripts
        inject_into_file "app/assets/stylesheets/store/all.css", " *= require store/spree_hosted_gateway\n", :before => /\*\//, :verbose => true
      end

      def add_images
        copy_file(File.join(File.dirname(__FILE__), '../../app/assets/images/store/hosted_gateway', "#{Rails.root}/vendor/assets/images/store/hosted_gateway"))
      end
    end
  end
end
