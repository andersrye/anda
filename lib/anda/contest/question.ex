defmodule Anda.Contest.Question do
  use Ecto.Schema
  import Ecto.Changeset

  schema "questions" do
    field :question, :string
    field :num_answers, :integer
    field :alternatives, {:array, :string}
    field :media_url, :string
    field :media_type, :string
    belongs_to :section, Anda.Contest.Section
    has_many :answers, Anda.Submission.Answer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:question, :num_answers, :alternatives, :section_id, :media_url, :media_type])
    |> validate_required([:question, :num_answers, :section_id])
  end
end
