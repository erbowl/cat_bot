Rails.application.routes.draw do
  match '/group/:id', to: 'webhook#edit', via: [:get, :post,:patch],as: "edit"
  post '/callback' => 'webhook#callback'
end
