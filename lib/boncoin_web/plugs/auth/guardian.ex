defmodule Boncoin.Auth.Guardian do
  use Guardian, otp_app: :boncoin
  alias Boncoin.Members

  # Returns something that can identify our user
  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  # Extract an id from the claims of JWT, then return the matching user
  def resource_from_claims(%{"sub" => id}) do
    # find_me_a_resource(claims["sub"]) # {:ok, resource} or {:error, reason}
    # {:ok, %{id: claims["sub"]}}
    case Members.get_user!(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end
end
