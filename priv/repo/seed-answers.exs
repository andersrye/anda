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
alias Anda.Submission
alias Anda.Submission.Answer
import Ecto.Query, warn: false

scope = %Anda.Accounts.Scope{user: %{id: 1}}
quiz = Repo.get_by!(Quiz, slug: "test-quiz")

answers = ["Eple","Pære", "Appelsin", "Drue", "Banan", "Kiwi", "Dragefrukt", "Mandarin", "Klementin", "Sitron", "Lime", "Mango", "Avokado"]

questions = Contest.get_quiz_w_questions(quiz.id, scope)
|> get_in([Access.key!(:sections), Access.all(), Access.key!(:questions)])
|> List.flatten()

Repo.delete_all(from s in Submission.Submission, where: s.quiz_id == ^quiz.id)

for i <- 0..1000 do
  submission = Submission.get_or_create_submission(quiz.id, :crypto.strong_rand_bytes(10) |> Base.encode64())
  Submission.update_submission_name(submission, :crypto.strong_rand_bytes(10) |> Base.encode64())
  for question <- questions do
    answer =     %Anda.Submission.Answer{question_id: question_id, submission_id: submission_id, index: index, text: Enum.random(answers)}
    Repo.insert!(answer)
  end
end
