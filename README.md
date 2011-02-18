HostedGateway
=============

There are a bunch of ActiveMerchant modules out there to provide a range of support for various payment gateways, not to mention the ones that Spree users themselves have created. Having reasonable support for external gateways though, is something that I've come to require in a couple of projects, so I've created this extension to help myself and others. 

An external gateway (in my mind), is basically a scenario where the customer needs to go to another site to pay, rather than payment happening with some magic behind the scenes. It's very simple, and cheap for store owners, which is why a whole lot of them use something like this method. For us developers though, there are definite downsides - basically, you're losing control of the checkout at the most important stage - payment. There's not much we can do about all these redirects, except to keep track of the orders as best we can.

This extension works in the following way - on the payment page, the customer clicks the continue button, and (thanks to some fancy Javascript), is POST'd to the payment gateway with a couple of parameters that a) The gateway needs, and b) We need to keep track of things. Once payment is made, the gateway does another postback, to us this time, usually with whatever parameters we gave the gateway as well as a couple others (like a status field to tell us whether the payment went through. This postback is directed towards a custom action of the checkout controller, that does some checking to make sure the payment has gone through (As far as we can know), and then updates the order, advancing it to the next step.

Installation
============

Really, like any Spree 0.30+ extension - add the following to your Gemfile, and run `bundle install`
`gem 'hosted_gateway', :git => 'https://www.github.com/joshmcarthur/spree-hosted-gateway.git'`

There aren't any migrations or public assets, so there is no need to run `rake hosted_gateway:install` (Though you can if you _really_ want.


Configuration
=============

From the admin interface, you can add an external gateway as a Payment Method (Look under the 'Configuration' tab). Once you've created an instance of the external gateway, you can enter the server (i.e. where to redirect to). 

Something that is kinda necessary with this extension (Since no gateway will be the same, and I've had to make some assumptions to make this generic), is to both understand what the code is doing, and to know how to get it working the way you want. In particular, you should check out the important `ExternalGateway` class - this is the actual payment method class, and contains the bulk of the logic. I have used Spree's _preferences_ system to hold configuration for a gateway, so you should also look at this - basically, this allows you to add preferences to send to the gateway, without having to touch my code. This extension handles preferences in an interesting way - basically, there are some 'reserved' preferences (i.e. `server`). These are preferences that ExternalGateway looks for by hardcoded name. All others, though, are automatically inserted into the form as hidden inputs to be POST'd to the gateway. This means you can use something like `ExternalGateway.send(:preference, :my_preference, :string)` in your own extension or initializer, etc. to add things to the form. I'm pretty sure most of the changes you will need to make will be to get the form data into the structure the gateway expects, so understanding how this works will make things much easier.

Consequences
============
* The major one is that the customer is gonna need Javascript so that we can manipulate the checkout form to POST that form data to the gateway - I couldn't find any better way to change where Spree was going to take you when you clicked that button. 
* At this stage, this extension is untested. That doesn't mean it doesn't work (for me), it just means that I'm not yet familiar enough with testing to write tests as I code without impacting my velocity - and this is for work, so it counts. I would be only to happy though, for someone who finds this useful to donate some time to writing one or two tests though - I love getting pull requests!
* There are some things that you'll probably have to do yourself - this extension will save you time, not do it for you - make sure you take the time to extend the gateway to send the data your gateway requires to avoid confusion, and also make sure you have a strategy to deal with those annoying customers who drop off the radar while they are halfway through the gateway payment process, leaving you with a half-completed order - perhaps some scope to send a weekly report? This sort of thing is probably outside the scope of this extension but I'll welcome discussion on the topic.


Enjoy!


Copyright (c) 2011 Josh McArthur[https://www.github.com/joshmcarthur], for 3Months.com[http://www.3months.com], released under the MIT License.
