defmodule Boncoin.CustomModules do
  import Ecto.Changeset

  # def get_first_error(errors_array) do
  #   [{title, {msg, _}} | _tail] = errors_array
  #   "Check first error : #{title} : #{msg}"
  # end

  def convert_fields_to_burmese_uni(params, keys_list) do
    params
      |> IO.inspect()
      |> Enum.into(%{}, fn {k, v} -> convert_field_to_burmese(k, v, keys_list) end)
      |> IO.inspect()
  end

  defp convert_field_to_burmese(key, value, keys_list) do
    case Enum.member?(keys_list, key) do
      false -> {key, value}
      true -> {key, Rabbit.zg2uni(value)}
    end
  end

  def convert_burmese(string, direction \\ nil) do
    case direction do
      nil ->
        # We don't know what is the caracter : convert it in unicode
        Rabbit.zg2uni(string)
      "uni" ->
        # Convert to unicode
        Rabbit.zg2uni(string)
      "zg" ->
        # Convert to Zawgyi
        Rabbit.uni2zg(string)
    end
  end

  def get_from_array(array) do
    Enum.fetch!(array, 0)
  end

  @moduledoc """
  Convert strings into booleans
  """
  def convert_boolean(string) do
    case string do
      "Y" -> true
      "y" -> true
      "yes" -> true
      "X" -> true
      "1" -> true
      _ -> false
    end
  end

  def convert_integer(string) do
    case Integer.parse(string) do
      {value, _} ->
        {:ok, value}
      _ ->
        {:error, string}
    end
  end

end
