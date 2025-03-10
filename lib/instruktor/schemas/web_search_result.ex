defmodule Instruktor.Schemas.WebSearchResult do
  @moduledoc """
  Schema for web search extraction results.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :query, :string
    field :total_results, :integer
    field :results, {:array, :map}
    field :suggestions, {:array, :string}
    field :page_number, :integer, default: 1
    field :metadata, :map, default: %{}
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:query, :total_results, :results, :suggestions, :page_number, :metadata])
    |> validate_required([:query, :results])
    |> validate_results()
  end

  defp validate_results(changeset) do
    results = get_field(changeset, :results) || []

    if Enum.all?(results, fn result -> 
      is_map(result) && Map.has_key?(result, "title") && Map.has_key?(result, "url")
    end) do
      changeset
    else
      add_error(changeset, :results, "each result must have title and url fields")
    end
  end
end 