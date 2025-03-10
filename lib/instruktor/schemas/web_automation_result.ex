defmodule Instruktor.Schemas.WebAutomationResult do
  @moduledoc """
  Schema for general web automation extraction results.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :title, :string
    field :summary, :string
    field :main_content, :string
    field :key_points, {:array, :string}
    field :links, {:array, :map}
    field :metadata, :map, default: %{}
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:title, :summary, :main_content, :key_points, :links, :metadata])
    |> validate_required([:title, :summary])
    |> validate_links()
  end

  defp validate_links(changeset) do
    links = get_field(changeset, :links) || []

    if Enum.all?(links, fn link -> 
      is_map(link) && Map.has_key?(link, "url") && Map.has_key?(link, "text")
    end) do
      changeset
    else
      add_error(changeset, :links, "each link must have url and text fields")
    end
  end
end 