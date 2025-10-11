defmodule Anda.Submission.Answer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "answers" do
    field :answer, :string
    field :index, :integer
    field :score, :float
    belongs_to :submission, Anda.Submission.Submission
    belongs_to :question, Anda.Contest.Question

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [:answer, :submission_id, :question_id, :index, :score])
    |> validate_required([:answer, :submission_id, :question_id, :index])
  end
end
