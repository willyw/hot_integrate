ActionController::Routing::Routes.draw do |map|
  map.login "/login", :controller => "user_sessions", :action => "new" # optional, this just sets the root route
  map.logout "/logout", :controller => "user_sessions", :action => "destroy" 

  map.resources :users
  map.resource :user_session
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
