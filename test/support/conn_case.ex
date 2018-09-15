defmodule BoncoinWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  import Boncoin.Factory
  alias Boncoin.Auth.Guardian

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import BoncoinWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint BoncoinWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Boncoin.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Boncoin.Repo, {:shared, self()})
    end
    # if tags[:internal_api] do
    #   Boncoin.Support.Helpers.launch_api()
    # end

    # Manage Guardian authentication
    # See https://medium.com/@simon.strom/how-to-test-controller-authenticated-by-guardian-in-elixir-phoenix-b9bfa141ed4
    {conn, user} = cond do
      tags[:admin_authenticated] == true ->
        user = insert(:admin_user)
        conn = Phoenix.ConnTest.build_conn()
          |> Guardian.Plug.sign_in(user, %{"typ" => "user-access"})
        {conn, user}
      tags[:member_authenticated] == true ->
        user = insert(:member_user)
        conn = Phoenix.ConnTest.build_conn()
          |> Guardian.Plug.sign_in(user, %{"typ" => "user-access"})
        {conn, user}
      true ->
        user = insert(:guest_user)
        {Phoenix.ConnTest.build_conn(), user}
    end
    {:ok, conn: conn, user: user}
  end

end
