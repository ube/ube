ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  map.home 'about/dashboard', :controller => 'about', :action => 'dashboard'

  # public actions
  map.search 'search', :controller => 'public', :action => 'search'
  map.status 'status', :controller => 'public', :action => 'status'
  map.contract 'contract', :controller => 'public', :action => 'contract'

  # global book actions
  map.books 'books', :controller => 'books', :action => 'index'
  map.all_books 'books/all', :controller => 'books', :action => 'all'

  # password reset actions
  map.connect 'people/forgot', :controller => 'people', :action => 'forgot'
  map.connect 'people/reset/:token', :controller => 'people', :action => 'reset'

  # resource routes
  map.resources :orders do |order|
    order.resources :order_items
  end

  map.resource :cart do |cart|
    cart.resources :cart_items
  end

  map.resources :sellers, :member => { :contract => :get, :pay_service_fee => :put, :unpay_service_fee => :put } do |seller|
    seller.resources :books
    seller.resource :reclamation
  end

  map.resources :held_books, :lost_books, :sold_books, :sessions
  map.resources :completed_orders, :member => { :receipt => :get }
  map.resources :barcodes
  map.resources :people, :member => { :change_password => :any }
  map.resource  :exchange, :member => { :hard_reset => :any, :soft_reset => :any }

  # default routes
  map.connect '', :controller => 'about', :action => 'home'
  map.connect ':controller/:action/:id'
end
