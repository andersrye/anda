defmodule QuestionFormData do
  use Ecto.Schema
  import Ecto.Changeset

  schema "question_form_data" do
    field :question, :string
    field :alternatives, :string
  end

  def changeset(question_form_data, params \\ %{}) do
    question_form_data
    |> cast(params, [:question, :alternatives])
    |> validate_required([:question, :alternatives])
  end

  def to_question_params(question_form_data) do
    alternatives =
      question_form_data.alternatives
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(String.length(&1) != 0))

    %{}
    |> Map.put("question", question_form_data.question)
    |> Map.put("question", alternatives)
  end

  def from_question(question) do
    %QuestionFormData{
      question: question.question,
      alternatives: question.alternatives |> Enum.join("\n")
    }
  end
end
