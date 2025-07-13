defmodule AndaWeb.QuizLiveTest do
  use AndaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Anda.ContestFixtures

  @create_attrs %{description: "some description", title: "some title"}
  @update_attrs %{description: "some updated description", title: "some updated title"}
  @invalid_attrs %{description: nil, title: nil}

  defp create_quiz(_) do
    quiz = quiz_fixture()
    %{quiz: quiz}
  end

  describe "Index" do
    setup [:create_quiz]

    test "lists all quiz", %{conn: conn, quiz: quiz} do
      {:ok, _index_live, html} = live(conn, ~p"/quiz")

      assert html =~ "Listing Quiz"
      assert html =~ quiz.description
    end

    test "saves new quiz", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/quiz")

      assert index_live |> element("a", "New Quiz") |> render_click() =~
               "New Quiz"

      assert_patch(index_live, ~p"/quiz/new")

      assert index_live
             |> form("#quiz-form", quiz: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#quiz-form", quiz: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/quiz")

      html = render(index_live)
      assert html =~ "Quiz created successfully"
      assert html =~ "some description"
    end

    test "updates quiz in listing", %{conn: conn, quiz: quiz} do
      {:ok, index_live, _html} = live(conn, ~p"/quiz")

      assert index_live |> element("#quiz-#{quiz.id} a", "Edit") |> render_click() =~
               "Edit Quiz"

      assert_patch(index_live, ~p"/quiz/#{quiz}/edit")

      assert index_live
             |> form("#quiz-form", quiz: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#quiz-form", quiz: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/quiz")

      html = render(index_live)
      assert html =~ "Quiz updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes quiz in listing", %{conn: conn, quiz: quiz} do
      {:ok, index_live, _html} = live(conn, ~p"/quiz")

      assert index_live |> element("#quiz-#{quiz.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#quiz-#{quiz.id}")
    end
  end

  describe "Show" do
    setup [:create_quiz]

    test "displays quiz", %{conn: conn, quiz: quiz} do
      {:ok, _show_live, html} = live(conn, ~p"/quiz/#{quiz}")

      assert html =~ "Show Quiz"
      assert html =~ quiz.description
    end

    test "updates quiz within modal", %{conn: conn, quiz: quiz} do
      {:ok, show_live, _html} = live(conn, ~p"/quiz/#{quiz}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Quiz"

      assert_patch(show_live, ~p"/quiz/#{quiz}/show/edit")

      assert show_live
             |> form("#quiz-form", quiz: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#quiz-form", quiz: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/quiz/#{quiz}")

      html = render(show_live)
      assert html =~ "Quiz updated successfully"
      assert html =~ "some updated description"
    end
  end
end
