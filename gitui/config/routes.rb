Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :repos, param: :name do
    resources :commits, param: :branch, only: [:show] do
      get '', on: :collection, action: :show
    end

    resources :commit, param: :sha, only: [:show] do
      get '', on: :collection, action: :show
    end
  end

  get 'repos/:repo_name/commit/:sha/*tree', to: 'commit#show', constraints: { sha: /[\h.]+/, tree: /.+/ }
  get 'repos/:name/:branch/*tree', to: 'repos#show_content', constraints: { tree: /.+/ }

  root 'repos#index'
end
