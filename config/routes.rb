ActionController::Routing::Routes.draw do |map|
  
  
  map.root   :controller => "downloads", :action => "welcome"
  map.oauth_ignite "/oauth_ignite", :controller => "downloads", :action =>"ignite_oauth" 
  map.return_oauth "/return_oauth", :controller => "downloads", :action => "from_oauth"

  
  
  map.login "/login", :controller => "user_sessions", :action => "new" # optional, this just sets the root route
  map.logout "/logout", :controller => "user_sessions", :action => "destroy" 

  map.resources :users, :has_many => :downloads
  map.resource :user_session
  
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
