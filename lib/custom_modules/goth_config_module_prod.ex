defmodule GothConfigModuleProd do
  use Goth.Config

  def init(config) do
    {:ok, Keyword.put(config, :json, "${GCP_CREDENTIALS}")}
  end
end
