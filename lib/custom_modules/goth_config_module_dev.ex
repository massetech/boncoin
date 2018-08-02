defmodule GothConfigModuleDev do
  use Goth.Config

  def init(config) do
    {:ok, Keyword.put(config, :json, System.get_env("GCP_CREDENTIALS"))}
  end
end
