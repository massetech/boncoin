defmodule Boncoin.Auth.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :boncoin,
    error_handler: Boncoin.Auth.ErrorHandler,
    module: Boncoin.Auth.Guardian

  # If there is a session token, validate it
  plug Guardian.Plug.VerifySession, claims: %{"typ" => "user-access"}
  # If there is an authorization header, validate it
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "user-access"}
  # Load the user if either of the verifications worked
  plug Guardian.Plug.LoadResource, allow_blank: true
end
