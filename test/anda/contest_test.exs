defmodule Anda.ContestTest do
  use Anda.DataCase

  alias Anda.Contest

  describe "quiz" do
    alias Anda.Contest.Quiz

    import Anda.ContestFixtures

    @invalid_attrs %{description: nil, title: nil}

    test "list_quiz/0 returns all quiz" do
      quiz = quiz_fixture()
      assert Contest.list_quiz() == [quiz]
    end

    test "get_quiz!/1 returns the quiz with given id" do
      quiz = quiz_fixture()
      assert Contest.get_quiz!(quiz.id) == quiz
    end

    test "create_quiz/1 with valid data creates a quiz" do
      valid_attrs = %{description: "some description", title: "some title"}

      assert {:ok, %Quiz{} = quiz} = Contest.create_quiz(valid_attrs)
      assert quiz.description == "some description"
      assert quiz.title == "some title"
    end

    test "create_quiz/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contest.create_quiz(@invalid_attrs)
    end

    test "update_quiz/2 with valid data updates the quiz" do
      quiz = quiz_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title"}

      assert {:ok, %Quiz{} = quiz} = Contest.update_quiz(quiz, update_attrs)
      assert quiz.description == "some updated description"
      assert quiz.title == "some updated title"
    end

    test "update_quiz/2 with invalid data returns error changeset" do
      quiz = quiz_fixture()
      assert {:error, %Ecto.Changeset{}} = Contest.update_quiz(quiz, @invalid_attrs)
      assert quiz == Contest.get_quiz!(quiz.id)
    end

    test "delete_quiz/1 deletes the quiz" do
      quiz = quiz_fixture()
      assert {:ok, %Quiz{}} = Contest.delete_quiz(quiz)
      assert_raise Ecto.NoResultsError, fn -> Contest.get_quiz!(quiz.id) end
    end

    test "change_quiz/1 returns a quiz changeset" do
      quiz = quiz_fixture()
      assert %Ecto.Changeset{} = Contest.change_quiz(quiz)
    end
  end

  describe "questions" do
    alias Anda.Contest.Question

    import Anda.ContestFixtures

    @invalid_attrs %{question: nil, num_answers: nil, alternatives: nil}

    test "list_questions/0 returns all questions" do
      question = question_fixture()
      assert Contest.list_questions() == [question]
    end

    test "get_question!/1 returns the question with given id" do
      question = question_fixture()
      assert Contest.get_question!(question.id) == question
    end

    test "create_question/1 with valid data creates a question" do
      valid_attrs = %{question: "some question", num_answers: 42, alternatives: "some alternatives"}

      assert {:ok, %Question{} = question} = Contest.create_question(valid_attrs)
      assert question.question == "some question"
      assert question.num_answers == 42
      assert question.alternatives == "some alternatives"
    end

    test "create_question/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contest.create_question(@invalid_attrs)
    end

    test "update_question/2 with valid data updates the question" do
      question = question_fixture()
      update_attrs = %{question: "some updated question", num_answers: 43, alternatives: "some updated alternatives"}

      assert {:ok, %Question{} = question} = Contest.update_question(question, update_attrs)
      assert question.question == "some updated question"
      assert question.num_answers == 43
      assert question.alternatives == "some updated alternatives"
    end

    test "update_question/2 with invalid data returns error changeset" do
      question = question_fixture()
      assert {:error, %Ecto.Changeset{}} = Contest.update_question(question, @invalid_attrs)
      assert question == Contest.get_question!(question.id)
    end

    test "delete_question/1 deletes the question" do
      question = question_fixture()
      assert {:ok, %Question{}} = Contest.delete_question(question)
      assert_raise Ecto.NoResultsError, fn -> Contest.get_question!(question.id) end
    end

    test "change_question/1 returns a question changeset" do
      question = question_fixture()
      assert %Ecto.Changeset{} = Contest.change_question(question)
    end
  end

  describe "sections" do
    alias Anda.Contest.Section

    import Anda.ContestFixtures

    @invalid_attrs %{description: nil, title: nil}

    test "list_sections/0 returns all sections" do
      section = section_fixture()
      assert Contest.list_sections() == [section]
    end

    test "get_section!/1 returns the section with given id" do
      section = section_fixture()
      assert Contest.get_section!(section.id) == section
    end

    test "create_section/1 with valid data creates a section" do
      valid_attrs = %{description: "some description", title: "some title"}

      assert {:ok, %Section{} = section} = Contest.create_section(valid_attrs)
      assert section.description == "some description"
      assert section.title == "some title"
    end

    test "create_section/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contest.create_section(@invalid_attrs)
    end

    test "update_section/2 with valid data updates the section" do
      section = section_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title"}

      assert {:ok, %Section{} = section} = Contest.update_section(section, update_attrs)
      assert section.description == "some updated description"
      assert section.title == "some updated title"
    end

    test "update_section/2 with invalid data returns error changeset" do
      section = section_fixture()
      assert {:error, %Ecto.Changeset{}} = Contest.update_section(section, @invalid_attrs)
      assert section == Contest.get_section!(section.id)
    end

    test "delete_section/1 deletes the section" do
      section = section_fixture()
      assert {:ok, %Section{}} = Contest.delete_section(section)
      assert_raise Ecto.NoResultsError, fn -> Contest.get_section!(section.id) end
    end

    test "change_section/1 returns a section changeset" do
      section = section_fixture()
      assert %Ecto.Changeset{} = Contest.change_section(section)
    end
  end
end
