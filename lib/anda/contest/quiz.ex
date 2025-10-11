defmodule Anda.Contest.Quiz do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quiz" do
    field :description, :string
    field :title, :string
    has_many :sections, Anda.Contest.Section

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quiz, attrs) do
    quiz
    |> cast(attrs, [:title, :description])
    |> validate_required([:title])
  end
end
