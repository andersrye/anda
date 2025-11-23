defmodule Anda.Contest.Quiz do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quiz" do
    field :description, :string
    field :title, :string
    field :mode, :string
    field :slug, :string
    has_many :sections, Anda.Contest.Section
    belongs_to :user, Anda.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quiz, attrs) do
    quiz
    |> cast(attrs, [:title, :description, :mode, :slug])
    |> validate_inclusion(:mode, ["hidden", "open", "closed"])
    |> validate_format(:slug, ~r/^[\w-]+$/)
    |> unique_constraint([:slug])
    |> validate_required([:mode, :slug])
  end
end
