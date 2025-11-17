defmodule Anda.Submission.Answer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "answers" do
    field :text, :string
    field :index, :integer
    field :score, :integer
    belongs_to :submission, Anda.Submission.Submission
    belongs_to :question, Anda.Contest.Question

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(answer, attrs \\ %{}) do
    answer
    |> cast(attrs, [:text, :submission_id, :question_id, :index, :score])
    |> validate_required([:text, :submission_id, :question_id, :index])
    |> update_change(:text, &String.trim/1)
    |> unique_constraint([:text, :question_id, :submission_id], message: "Du kan ikke skrive det samme flere ganger")
  end

  def changeset(answer, "number", attrs) do
    answer
    |> changeset(attrs)
    |> validate_format(:text, ~r/^\d+$/,  message: "Dette skulle helst vært et tall")
  end

  def changeset(answer, "football-score", attrs) do
    regex = ~r/^(\d+)\W+(\d+)$/
    answer
    |> changeset(attrs)
    |> validate_format(:text, regex, message: "Skriv inn typ \"1-0\"")
    |> update_change(:text, fn ans ->
      match = Regex.run(regex, ans)
      dbg(match)
      if match do
        match |> Enum.drop(1) |> Enum.join("-") |> dbg()
      else
        ans
      end
     end)
  end

  def changeset(answer, _, attrs) do
    answer
    |> changeset(attrs)
  end

  def create(question_id, submission_id, index) do
    %Anda.Submission.Answer{question_id: question_id, submission_id: submission_id, index: index, text: ""}
  end
end
