defmodule Anda.Contest.Question do
  use Ecto.Schema
  import Ecto.Changeset

  schema "questions" do
    field :text, :string
    field :type, :string
    field :num_answers, :integer
    field :alternatives, {:array, :string}
    field :media_url, :string
    field :media_type, :string
    field :media_aspect_ratio, :float
    field :position, :integer
    belongs_to :section, Anda.Contest.Section
    has_many :answers, Anda.Submission.Answer

    field :total_answer_count, :integer, virtual: true
    field :scored_answer_count, :integer, virtual: true
    field :rank, :integer, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:text, :num_answers, :alternatives, :section_id, :media_url, :media_type, :media_aspect_ratio, :type, :position])
    |> validate_required([:text, :num_answers, :section_id, :type, :position])
  end
end
