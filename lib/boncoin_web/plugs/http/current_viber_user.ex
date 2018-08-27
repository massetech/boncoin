defmodule Boncoin.Viber.CurrentUser do
  import Plug.Conn

  alias Boncoin.Members

  def init(opts), do: opts
  def call(conn, _opts) do
    viber_sig = conn.params["sig"]
    viber_id = conn.params["sender"]["id"] || conn.params["user"]["id"] || conn.params["id"] || nil

    if viber_id == nil, do: user = nil, else: user = Members.get_user_by_viber_id(viber_id)

    conn
      |> assign(:current_user, user)
  end
end
