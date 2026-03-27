defmodule Anda.Contest do
  import Ecto.Query, warn: false
  alias AndaWeb.Endpoint
  alias Anda.Accounts.Scope
  alias Ecto.Multi
  alias Anda.Submission.Answer
  alias Anda.Repo
  alias Anda.Contest.Quiz
  alias Anda.Contest.Section
  alias Anda.Contest.Question

  ### QUIZ ###

  def list_quiz(%Scope{} = scope) do
    Repo.all(from quiz in Quiz, where: quiz.user_id == ^scope.user.id)
  end

  def get_quiz!(id, %Scope{} = scope) do
    Repo.get_by!(Quiz, id: id, user_id: scope.user.id)
  end

  def get_quiz_by_slug!(slug) do
    Repo.get_by!(Quiz, slug: slug)
  end

  def get_quiz_w_questions(id, %Scope{} = scope) do
    query =
      from quiz in Quiz,
        where: quiz.id == ^id and quiz.user_id == ^scope.user.id,
        left_join: s in Section,
        on: s.quiz_id == quiz.id,
        left_join: q in Question,
        on: q.section_id == s.id,
        preload: [sections: {s, questions: q}],
        order_by: [s.position, q.id]

    Repo.all(query) |> Enum.at(0)
  end

  def get_quiz_w_questions_by_slug(slug) do
    query =
      from quiz in Quiz,
        where: quiz.slug == ^slug,
        left_join: s in Section,
        on: s.quiz_id == quiz.id,
        left_join: q in Question,
        on: q.section_id == s.id,
        preload: [sections: {s, questions: q}],
        order_by: [s.position, q.id]

    Repo.all(query) |> Enum.at(0)
  end

  def get_quiz_w_question_count(id, %Scope{} = scope) do
    query =
      from quiz in Quiz,
        where: quiz.id == ^id and quiz.user_id == ^scope.user.id,
        left_join: s in Section,
        on: s.quiz_id == quiz.id,
        left_join: q in Question,
        on: q.section_id == s.id,
        select: %{id: quiz.id, title: quiz.title, slug: quiz.slug, question_count: sum(q.num_answers)},
        group_by: quiz.id

    Repo.all(query) |> Enum.at(0)
  end

  def get_quiz_id_from_slug(slug) do
    Repo.one(from quiz in Quiz, select: quiz.id, where: quiz.slug == ^slug)
  end

  def create_quiz(attrs \\ %{}, %Scope{} = scope) do
    %Quiz{user_id: scope.user.id}
    |> Quiz.changeset(attrs)
    |> Repo.insert()
  end

  def update_quiz(%Quiz{} = quiz, attrs, %Scope{} = scope) do
    if quiz.user_id != scope.user.id, do: raise("Forbidden!")

    with {:ok, quiz} <-
           quiz
           |> Quiz.changeset(attrs)
           |> Repo.update() do
      Endpoint.broadcast("quiz:#{quiz.id}", "quiz_updated", quiz)
      {:ok, quiz}
    end
  end

  def delete_quiz(%Quiz{} = quiz, %Scope{} = scope) do
    # TODO!
    if quiz.user_id != scope.user.id, do: raise("Forbidden!")
    Repo.delete(quiz)
  end

  def change_quiz(%Quiz{} = quiz, attrs \\ %{}) do
    Quiz.changeset(quiz, attrs)
  end

  ### QUESTIONS ###

  def list_questions(section_id, %Scope{} = scope) do
    query =
      from q in Question,
        select: q,
        join: s in Section,
        on: s.id == q.section_id,
        join: quiz in Quiz,
        on: quiz.id == s.quiz_id,
        where: q.section_id == ^section_id and quiz.user_id == ^scope.user.id

    Repo.all(query)
  end

  def answer_counts(section_id) do
    query =
      from q in Question,
        where: q.section_id == ^section_id,
        join: a in Answer,
        on: a.question_id == q.id,
        select: %{count: count(a), question_id: q.id},
        group_by: q.id

    Repo.all(query)
  end

  def get_question!(id, %Scope{} = scope) do
    query =
      from q in Question,
        select: q,
        join: s in Section,
        on: s.id == q.section_id,
        join: quiz in Quiz,
        on: quiz.id == s.quiz_id,
        where: q.id == ^id and quiz.user_id == ^scope.user.id

    Repo.one!(query)
  end

  def create_question(attrs \\ %{}, %Scope{} = scope) do
    # sjekk om section tilhører riktig scope
    get_section!(attrs.section_id, %Scope{} = scope)

    %Question{}
    |> Question.changeset(attrs)
    |> Repo.insert()
  end

  def update_question(%Question{} = question, attrs) do
    question
    |> Question.changeset(attrs)
    |> Repo.update()
  end

  def delete_question(%Question{} = question) do
    Repo.delete(question)
  end

  def change_question(%Question{} = question, attrs \\ %{}) do
    Question.changeset(question, attrs)
  end

  ### SECTIONS ###

  def list_sections(quiz_id, %Scope{} = scope) do
    query =
      from s in Section,
        select: s,
        join: quiz in Quiz,
        on: quiz.id == s.quiz_id,
        where: s.quiz_id == ^quiz_id and quiz.user_id == ^scope.user.id,
        order_by: s.position

    Repo.all(query)
  end

  def get_section!(id, %Scope{} = scope) do
    query =
      from s in Section,
        select: s,
        join: quiz in Quiz,
        on: quiz.id == s.quiz_id,
        where: s.id == ^id and quiz.user_id == ^scope.user.id

    Repo.one!(query)
  end


  def create_section(attrs \\ %{}, %Scope{} = scope) do
    # TODO: rydd opp, ta inn faste parametre, ikke attrs
    Repo.transact(fn ->
      quiz_id = Map.get(attrs, "quiz_id")
      #sjekk om quiz tilhører scope
      get_quiz!(quiz_id, scope)
      max = Repo.one(from s in Section, select: max(s.position), where: s.quiz_id == ^quiz_id)
      position = if max, do: max + 1, else: 0
      attrs = Map.put(attrs, "position", position)

      %Section{}
      |> Section.changeset(attrs)
      |> Repo.insert()
    end)
  end

  def update_section(%Section{} = section, attrs) do
    section
    |> Section.changeset(attrs)
    |> Repo.update()
  end

  def delete_section(%Section{} = section) do
    Repo.delete(section)
  end

  def change_section(%Section{} = section, attrs \\ %{}) do
    Section.changeset(section, attrs)
  end

  def move_section_by(%Section{} = section, offset) do
    sections =
      Repo.all(from s in Section, where: s.quiz_id == ^section.quiz_id, order_by: s.position)

    current_index = Enum.find_index(sections, fn s -> s.id == section.id end)

    new_index = max(0, min(Enum.count(sections) - 1, current_index + offset))

    {:ok, res} =
      sections
      |> List.delete_at(current_index)
      |> List.insert_at(new_index, section)
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn {s, i}, m ->
        changeset = Section.changeset(s, %{"position" => i})
        Multi.update(m, {:update, i}, changeset)
      end)
      |> Repo.transact()

    changed = Map.values(res)
    Endpoint.broadcast("quiz:#{section.quiz_id}:section", "section_updated", changed)
  end

  def move_section_up(%Section{} = section) do
    move_section_by(section, -1)
  end

  def move_section_down(%Section{} = section) do
    move_section_by(section, 1)
  end
end
