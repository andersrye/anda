defmodule Anda.Contest.Section do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sections" do
    field :description, :string
    field :title, :string
    has_many :questions, Anda.Contest.Question
    belongs_to :quiz, Anda.Contest.Quiz

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [:title, :description, :quiz_id])
    |> validate_required([:title, :quiz_id])
  end
end
