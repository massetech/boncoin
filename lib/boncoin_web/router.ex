defmodule BoncoinWeb.Router do
  use BoncoinWeb, :router
  require Ueberauth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Boncoin.Plug.LoadSelects
    plug Boncoin.Plug.Locale
    plug Boncoin.Plug.SearchParams
    plug Boncoin.Plug.LoadAdds
    plug Boncoin.Plug.Location
  end

  pipeline :auth do
    plug Boncoin.Auth.Pipeline
    plug Boncoin.Auth.CurrentUser
    plug Boncoin.Auth.SetApiToken
  end

  pipeline :login_required do
    plug Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "user-access"}
  end

  pipeline :admin_required do
    plug Boncoin.Plugs.RequireAdmin
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Boncoin.Auth.CheckApiAccess
  end

  # ---------------  SCOPES ----------------------------------

  scope "/api", BoncoinWeb do
    pipe_through [:api]
    post "/viber", ViberController, :callback
    post "/phone", UserController, :check_phone
    post "/add_offers", AnnounceController, :add_offers_to_public_index
    post "/alert", AnnounceController, :add_alert_to_offer
    post "/count_clic", AnnounceController, :add_click_on_offer
  end

  scope "/", BoncoinWeb do
    pipe_through [:browser, :auth]
    get "/", MainController, :welcome, as: :root
    get "/conditions", MainController, :conditions
    get "/about", MainController, :about
    get "/conversations", MainController, :conversations
    get "/offers", AnnounceController, :public_index, as: :public_offers
    scope "/user" do
      get "/offer", UserController, :new_user_announce
      post "/create", UserController, :create_announce
    end
    # resources "/offers", AnnounceController, only: [:new, :create]
    get "/offer/:link", AnnounceController, :edit
    get "/close", AnnounceController, :close
  end

  scope "/admin", BoncoinWeb do
    pipe_through [:browser, :auth, :login_required, :admin_required]
    get "/dashboard", MainController, :dashboard
    resources "/users", UserController
    resources "/familys", FamilyController
    resources "/categorys", CategoryController
    resources "/divisions", DivisionController
    resources "/townships", TownshipController
    resources "/images", ImageController, except: [:edit, :update]
    resources "/announces", AnnounceController, except: [:new, :create]
    get "/treat", AnnounceController, :treat
  end

  scope "/viber", BoncoinWeb do
    pipe_through [:browser]
    get "/connect", ViberController, :connect
    get "/disconnect", ViberController, :disconnect
  end

  scope "/auth", BoncoinWeb do
    pipe_through [:browser]
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

end
