defmodule Anda.Submission do
  import Ecto.Query, warn: false
  alias Anda.Submission
  alias Anda.Repo

  alias Anda.Submission.Submission
  alias Anda.Submission.Answer

  def create_submission(quiz_id, secret) do
    id = String.to_integer(quiz_id)

    %Submission{secret: secret, name: "", quiz_id: id}
    |> Submission.changeset(%{})
    |> Repo.insert()
  end

  def get_submission_by_secret(quiz_id, secret) do
    Repo.get_by(Submission, secret: secret, quiz_id: quiz_id) |> Repo.preload(:answers)
  end

  def update_submission_name(submission, name) do
    res =
      submission
      |> Submission.changeset(%{"name" => name})
      |> Repo.update()

    case res do
      {:ok, submission} ->
        Phoenix.PubSub.broadcast(
          Anda.PubSub,
          "submission:#{submission.id}",
          {:submission_updated, submission}
        )
    end

    res
  end

  def submit_answer(answer, new_answer, question, submission) do
    dbg(answer)

    res =
      answer
      |> Answer.changeset(%{"answer" => new_answer, "score" => nil})
      |> Repo.insert_or_update()

    case res do
      {:ok, inserted_answer} ->
        Phoenix.PubSub.broadcast(
          Anda.PubSub,
          "answer:#{answer.submission_id}",
          {:answer_updated, inserted_answer}
        )

        if is_nil(answer.id) do
          Phoenix.PubSub.broadcast(
            Anda.PubSub,
            "quiz:#{submission.quiz_id}:new_answer",
            {:new_answer,
             %{
               question_id: answer.question_id,
               section_id: question.section_id
             }}
          )
        end
    end

    res
  end

  def get_all_unique_answers(question_id) do
    Repo.all(
      from(a in Answer,
        select: fragment("lower(?)", a.answer),
        distinct: fragment("lower(?)", a.answer),
        # distinct: a.answer,
        order_by: a.answer,
        where: a.question_id == ^question_id
      )
    )
  end

  def get_all_unique_answers2(question_id) do
    Repo.all(
      from(a in Answer,
        select: {fragment("lower(?)", a.answer), fragment("array_agg(?)", a.id)},
        group_by: fragment("lower(?)", a.answer),
        where: a.question_id == ^question_id
      )
    )
  end

  def set_scores(scores) do
    Repo.transact(fn ->
      for {score, ids} <- scores do
        num_ids = Enum.count(ids)
        answers = from a in Answer, where: a.id in ^ids
        {^num_ids, _} = Repo.update_all(answers, set: [score: score])
      end

      {:ok, nil}
    end)
  end

  def get_leaderboard(quiz_id) do
    Repo.all(
      from s in Submission,
        where: s.quiz_id == ^quiz_id,
        join: a in Answer,
        on: a.submission_id == s.id,
        select: {s.id, s.name, sum(a.score)},
        group_by: s.id,
        order_by: [desc: sum(a.score)]
    )
  end
end
