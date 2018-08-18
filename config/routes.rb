Rails.application.routes.draw do
  root to: 'spreadsheets#index'
  resources :spreadsheets, only: [:index]
end
