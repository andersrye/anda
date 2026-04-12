# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Anda.Repo.insert!(%Anda.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Anda.Repo
alias Anda.Contest.Question
alias Anda.Contest.Section
alias Anda.Contest.Quiz
alias Anda.Contest
import Ecto.Query, warn: false

scope = %Anda.Accounts.Scope{user: %{id: 1}}
quiz = Repo.get_by!(Quiz, slug: "test-quiz")

Repo.delete_all(from s in Section, where: s.quiz_id == ^quiz.id)

for i <- 0..40 do
  {:ok, section} = Contest.create_section(%{"title" => "Seksjon #{i}", "quiz_id" => quiz.id}, scope)
  for j <- 0..5 do
    Contest.create_question(%{
      text: "Spørsmål #{i}-#{j}",
      text_rendered: "<p>Spørsmål #{i}-#{j}</p>",
      section_id: section.id,
      type: "text",
      num_answers: 1,
      alternatives: []
      }, scope)
  end
end
