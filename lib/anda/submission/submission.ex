defmodule Anda.Submission.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "submissions" do
    field :name, :string
    field :secret, :string
    field :tags, {:array, :string}
    has_many :answers, Anda.Submission.Answer
    belongs_to :quiz, Anda.Contest.Quiz

    timestamps(type: :utc_datetime)
  end

  def changeset(section, attrs \\ %{}) do
    section
    |> cast(attrs, [:name, :secret, :quiz_id, :tags])
    |> validate_required([:secret, :quiz_id])
    |> unique_constraint([:name, :quiz_id])
  end
end
