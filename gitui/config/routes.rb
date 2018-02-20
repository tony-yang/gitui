Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :repos, param: :name
  get 'repos/:name/:branch/*tree', to: 'repos#show_content', constraints: { tree: /.+/}

  root 'repos#index'
end
