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
  end

  pipeline :auth do
    plug Boncoin.Auth.Pipeline
    plug Boncoin.Auth.CurrentUser
  end

  pipeline :login_required do
    plug Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "user-access"}
  end

  # pipeline :admin_required do
  #   plug Boncoin.Plugs.RequireAdmin
  # end

  pipeline :api do
    plug :accepts, ["json"]
    plug Boncoin.Viber.CurrentUser
    # plug Boncoin.Plug.CheckInput
    # plug Boncoin.Auth.Pipeline
    # plug Boncoin.Auth.CurrentUser
    # plug Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "user-access"}
  end

  # ---------------  SCOPES ----------------------------------
  scope "/api", BoncoinWeb do
    pipe_through :api
    post "/viber", ViberController, :callback
  end

  scope "/", BoncoinWeb do
    pipe_through [:browser, :auth]
    get "/", MainController, :welcome, as: :root
    get "/offers", MainController, :public_index, as: :public_offers
    get "/conditions", MainController, :conditions
    get "/about", MainController, :about
    get "/viber", MainController, :viber
    resources "/announces", AnnounceController, only: [:new, :create]
  end

  scope "/admin", BoncoinWeb do
    pipe_through [:browser, :auth, :login_required]
    get "/dashboard", MainController, :dashboard
    resources "/users", UserController
    resources "/familys", FamilyController
    resources "/categorys", CategoryController
    resources "/divisions", DivisionController
    resources "/townships", TownshipController
    resources "/images", ImageController, except: [:edit, :update]
    resources "/announces", AnnounceController, except: [:new, :create]
    get "/treat_announce", AnnounceController, :treat_announce
  end

  scope "/viber", BoncoinWeb do
    pipe_through :browser
    get "/connect", ViberController, :connect
    get "/disconnect", ViberController, :disconnect
  end

  scope "/auth", BoncoinWeb do
    pipe_through :browser
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

end
