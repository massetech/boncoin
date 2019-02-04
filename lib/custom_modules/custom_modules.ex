defmodule Boncoin.CustomModules do
  import Ecto.Changeset

  def get_changeset_error(changeset) do
    {key, {msg, type}} = List.first(changeset.errors)
    msg
  end

  def list_of_months() do
    [ January: 1,
      February: 2,
      March: 3,
      April: 4,
      May: 5,
      June: 6,
      July: 7,
      August: 8,
      September: 9,
      October: 10,
      November: 11,
      Decembe: 12
    ]
  end

  def list_of_years() do
    [2019, 2020, 2021, 2022]
  end

  def convert_fields_to_burmese_uni(%{"language" => language} = params, keys_list) do
    case language do
      "dz" -> Enum.into(params, %{}, fn {k, v} -> convert_field_to_uni(k, v, keys_list) end)
      _ -> params
    end
  end
  def convert_fields_to_burmese_uni(params, keys_list) do
    params
  end

  defp convert_field_to_uni(key, nil, keys_list), do: {key, nil}
  defp convert_field_to_uni(key, value, keys_list) do
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

  def map_keys_to_atoms(map) do
    for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
  end

  def map_keys_to_strings(map) do
    for {key, val} <- map, into: %{}, do: {Atom.to_string(key), val}
  end

end
