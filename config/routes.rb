Rails.application.routes.draw do
  resources :comments do
    put :like, on: :member 
    put :dislike, on: :member
  end
  resources :contributions do
    get :like, on: :member 
    put :dislike, on: :member
    get :show_news, on: :collection
  end
  devise_for :users
  get 'users/:id/edit', to: 'users#edit', as: 'users_edit'
  get 'contribution/:id', to: 'contributions#show_one'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'contributions#index' 
end
