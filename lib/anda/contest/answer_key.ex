defmodule Anda.Contest.AnswerKey do
  use Ecto.Schema
  import Ecto.Changeset

  schema "answer_key" do
    field :text, :string
    field :score, :integer
    belongs_to :question, Anda.Contest.Question
    timestamps(type: :utc_datetime)
  end

  def changeset(question, attrs) do
    question
    |> cast(attrs, [
      :text,
      :score,
      :question_id,
    ])
    |> validate_required([:text, :score, :question_id])
  end
end
