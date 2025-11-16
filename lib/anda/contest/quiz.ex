defmodule Anda.Contest.Quiz do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quiz" do
    field :description, :string
    field :title, :string
    field :mode, :string
    has_many :sections, Anda.Contest.Section
    belongs_to :user, Anda.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quiz, attrs) do
    quiz
    |> cast(attrs, [:title, :description, :mode])
    |> validate_inclusion(:mode, ["hidden", "open", "closed"])
    |> validate_required([:mode])
  end
end
