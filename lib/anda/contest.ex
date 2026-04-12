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
        order_by: [s.position, q.position]

    Repo.one(query)
  end

  def get_quiz_w_questions_and_empty_answers(id, %Scope{} = scope) do
    get_quiz_w_questions(id, scope)
    |> update_in(
      [
        Access.key!(:sections),
        Access.all(),
        Access.key!(:questions),
        Access.all()
      ],
      fn question ->
        struct(question,
          answers:
            Enum.map(0..(question.num_answers - 1), fn index ->
              Answer.create(question.id, -1, index)
            end)
        )
      end
    )
  end

  # TODO: ikke bruk join her?
  def get_quiz_w_questions_w_answer_stats(id, %Scope{} = scope) do
    subquery =
      from q in Question,
        left_join: s in Section,
        on: s.id == q.section_id,
        left_join: a in Answer,
        on: a.question_id == q.id,
        select: %{q | total_answer_count: count(a), scored_answer_count: count(a.score)},
        group_by: [q.id],
        where: s.quiz_id == parent_as(:quiz).id

    query =
      from quiz in Quiz,
        as: :quiz,
        where: quiz.id == ^id and quiz.user_id == ^scope.user.id,
        left_join: s in Section,
        on: s.quiz_id == quiz.id,
        left_lateral_join: q in subquery(subquery),
        on: q.section_id == s.id,
        preload: [sections: {s, questions: q}],
        order_by: [s.position, q.position]

    Repo.one(query)
  end

  # preload uten join:
  def get_quiz_w_questions_w_answer_stats2(id, %Scope{} = scope) do
    sections = from s in Section, order_by: s.position

    questions =
      from q in Question,
        left_join: s in Section,
        on: q.section_id == s.id,
        left_join: a in Answer,
        on: a.question_id == q.id,
        select: %{q | total_answer_count: count(a), scored_answer_count: count(a.score)},
        group_by: [q.id],
        order_by: q.position,
        # vet ikke hvorfor, men denne ekstra joinen gjør at den bruker indexen...
        where: s.quiz_id == ^id

    query =
      from quiz in Quiz,
        where: quiz.id == ^id and quiz.user_id == ^scope.user.id,
        preload: [sections: ^{sections, [questions: questions]}]

    Repo.one(query)
  end

  def get_quiz_w_questions_w_answers(id, submission_id, %Scope{} = scope) do
    subquery =
      from q in Question,
        left_join: a in Answer,
        on: a.question_id == q.id and a.submission_id == ^submission_id,
        select: %{q | answers: a},
        group_by: [q.id]

    query =
      from quiz in Quiz,
        where: quiz.id == ^id and quiz.user_id == ^scope.user.id,
        left_join: s in Section,
        on: s.quiz_id == quiz.id,
        left_join: q in subquery(subquery),
        on: q.section_id == s.id,
        preload: [sections: {s, questions: q}],
        order_by: [s.position, q.position]

    Repo.one(query)
  end

  def get_quiz_w_questions2(id, %Scope{} = scope) do
    subquery =
      from q in Question,
        left_join: a in Answer,
        on: a.question_id == q.id,
        left_join: s in Section,
        on: s.id == q.section_id,
        select: %{
          q
          | total_answer_count: count(a),
            scored_answer_count: count(a.score),
            number: over(dense_rank(), :number)
        },
        windows: [number: [order_by: [s.position, q.position]]],
        group_by: [s.id, q.id]

    query =
      from quiz in Quiz,
        where: quiz.id == ^id and quiz.user_id == ^scope.user.id,
        left_join: s in Section,
        on: s.quiz_id == quiz.id,
        left_join: q in subquery(subquery),
        on: q.section_id == s.id,
        preload: [sections: {s, questions: q}],
        order_by: [s.position, q.position]

    Repo.one(query)
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
        order_by: [s.position, q.position]

    Repo.one(query)
  end

  def get_quiz_w_questions_and_answers(quiz_id, submission_id) do
    answers_query =
      from a in Answer,
        where: a.submission_id == ^submission_id,
        order_by: a.index

    query =
      from quiz in Quiz,
        where: quiz.id == ^quiz_id,
        left_join: s in Section,
        on: s.quiz_id == quiz.id,
        left_join: q in Question,
        on: q.section_id == s.id,
        preload: [sections: {s, questions: {q, answers: ^answers_query}}],
        order_by: [s.position, q.position]

    quiz = Repo.one(query)

    update_in(
      quiz,
      [
        Access.key!(:sections),
        Access.all(),
        Access.key!(:questions),
        Access.all()
      ],
      fn question ->
        answers =
          Enum.map(0..(question.num_answers - 1), fn index ->
            exisiting_answer = Enum.find(question.answers, &(&1.index == index))

            if(exisiting_answer) do
              exisiting_answer
            else
              Answer.create(question.id, submission_id, index)
            end
          end)

        struct(question, answers: answers)
      end
    )
  end

  def get_quiz_w_question_count(id, %Scope{} = scope) do
    query =
      from quiz in Quiz,
        where: quiz.id == ^id and quiz.user_id == ^scope.user.id,
        left_join: s in Section,
        on: s.quiz_id == quiz.id,
        left_join: q in Question,
        on: q.section_id == s.id,
        select: %{quiz | question_count: sum(q.num_answers)},
        group_by: quiz.id

    Repo.one(query)
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
        where: q.section_id == ^section_id and quiz.user_id == ^scope.user.id,
        order_by: q.position

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
    Repo.transact(fn ->
      section_id = attrs.section_id
      # sjekk om section tilhører riktig scope
      get_section!(section_id, scope)

      max =
        Repo.one(from q in Question, select: max(q.position), where: q.section_id == ^section_id)

      position = if max, do: max + 1, else: 0
      attrs = Map.put(attrs, :position, position)

      %Question{}
      |> Question.changeset(attrs)
      |> Repo.insert()
    end)
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
      # sjekk om quiz tilhører scope
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
    Endpoint.broadcast("quiz:#{section.quiz_id}:section", "sections_updated", changed)
  end

  def move_section_up(%Section{} = section) do
    move_section_by(section, -1)
  end

  def move_section_down(%Section{} = section) do
    move_section_by(section, 1)
  end

  def move_question_by(%Question{} = question, offset) do
    quiz_id = Repo.one(from s in Section, select: s.quiz_id, where: s.id == ^question.section_id)

    questions =
      Repo.all(
        from q in Question, where: q.section_id == ^question.section_id, order_by: q.position
      )

    current_index = Enum.find_index(questions, fn q -> q.id == question.id end)

    new_index = max(0, min(Enum.count(questions) - 1, current_index + offset))

    {:ok, res} =
      questions
      |> List.delete_at(current_index)
      |> List.insert_at(new_index, question)
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn {q, i}, m ->
        changeset = Question.changeset(q, %{"position" => i})
        Multi.update(m, {:update, i}, changeset)
      end)
      |> Repo.transact()

    changed = Map.values(res)

    Endpoint.broadcast(
      "quiz:#{quiz_id}:question",
      "questions_updated",
      changed
    )
  end

  def move_question_up(%Question{} = question) do
    move_question_by(question, -1)
  end

  def move_question_down(%Question{} = question) do
    move_question_by(question, 1)
  end
end
