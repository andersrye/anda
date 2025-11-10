defmodule Anda.Submission do
  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Anda.Contest.Quiz
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

  def get_submission(submission_id) do
    Repo.get(Submission, submission_id) |> Repo.preload(:answers)
  end

  def get_submission_by_secret(quiz_id, secret) do
    Repo.get_by(Submission, secret: secret, quiz_id: quiz_id) |> Repo.preload(:answers)
  end

  def update_submission_name(submission, name) do
    {status, _} =
      res =
      submission
      |> Submission.changeset(%{"name" => name})
      |> Repo.update()

    if status == :ok do
      Phoenix.PubSub.broadcast(
        Anda.PubSub,
        "submission:#{submission.id}",
        {:submission_updated, submission}
      )
    end

    res
  end

  def submit_answer(answer, new_answer, question, submission) do
    res =
      answer
      |> Answer.changeset(question.type, %{"answer" => new_answer, "score" => nil})
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

        res

      _ ->
        res
    end

    res
  end

  defp new_answer(question, submission, index) do
    %Answer{
      submission_id: submission.id,
      question_id: question.id,
      index: index
    }
  end

  def submit_answers(existing_answers, new_answers, question, submission) do
    multi =
      new_answers
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn {a, index}, m ->
        existing_answer = Enum.find(existing_answers, fn a -> a.index == index end)

        cond do
          a != "" ->
            answer = existing_answer || new_answer(question, submission, index)
            changeset = Answer.changeset(answer, question.type, %{"text" => a, "score" => nil})
            Multi.insert_or_update(m, {:update_answer, index}, changeset)

          existing_answer ->
            Multi.delete(m, {:delete_answer, index}, existing_answer)

          true ->
            m
        end
      end)

    Repo.transact(multi)
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
        select: {a.text, fragment("array_agg(?)", a.id)},
        group_by: a.text,
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

  def get_leaderboard(quiz_id, tag \\ nil) do
    query =
      from s in Submission,
        where: s.quiz_id == ^quiz_id,
        left_join: a in Answer,
        on: a.submission_id == s.id,
        select: {s.id, s.name, sum(a.score)},
        group_by: s.id,
        order_by: [desc: sum(a.score)]

    query = if tag, do: query |> where([s], ^tag in s.tags), else: query

    Repo.all(query)
  end

  def get_submissions(quiz_id) do
    Repo.all(
      from s in Submission,
        where: s.quiz_id == ^quiz_id,
        left_join: a in Answer,
        on: a.submission_id == s.id,
        select: %{id: s.id, name: s.name, num_answers: count(a), tags: s.tags},
        group_by: s.id
    )
  end

  def add_tag(submission_id, tag, scope) do
    submission = Repo.get!(Submission, submission_id)
    Repo.get_by!(Quiz, id: submission.quiz_id, user_id: scope.user.id)

    new_tags =
      [tag | submission.tags]
      |> Enum.uniq()
      |> Enum.sort()

    submission
    |> Submission.changeset(%{tags: new_tags})
    |> Repo.update()
  end

  def remove_tag(submission_id, tag, scope) do
    submission = Repo.get!(Submission, submission_id)
    Repo.get_by!(Quiz, id: submission.quiz_id, user_id: scope.user.id)
    new_tags = Enum.filter(submission.tags, fn t -> t != tag end)

    submission
    |> Submission.changeset(%{tags: new_tags})
    |> Repo.update()
  end

  def get_all_tags() do
    Repo.all(from s in Submission, select: fragment("unnest(?)", s.tags), distinct: true)
  end
end
