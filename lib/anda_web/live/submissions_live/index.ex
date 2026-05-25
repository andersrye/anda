defmodule AndaWeb.SubmissionsLive.Index do
  use AndaWeb, :live_view

  alias AndaWeb.SubmissionsLive.Form
  alias AndaWeb.SecretUrl
  alias Anda.Submission
  alias Anda.Contest

  @impl true
  def mount(%{"quiz_id" => quiz_id}, _session, socket) do
    {:ok,
     socket
     |> assign_new(:quiz, fn ->
       Contest.get_quiz_w_question_count(quiz_id, socket.assigns.current_scope)
     end)
     |> assign_new(:submissions, fn -> Submission.get_submissions(quiz_id) end)
     |> assign(show_copy_url: nil)
     |> assign(show_delete_submission_modal: nil)}
  end

  @impl true
  def handle_params(%{"quiz_id" => quiz_id} = params, uri, socket) do
    submission_id = Map.get(params, "submission_id")

    tags =
      if socket.assigns.live_action == :add_tag, do: Submission.get_all_tags(quiz_id), else: nil

    {:noreply,
     socket
     |> assign(submission_id: submission_id)
     |> assign(current_uri: uri)
     |> assign(tags: tags)}
  end

  @impl true
  def handle_event("add_tag", %{"submission-id" => submission_id, "tag" => tag}, socket) do
    submission_id = String.to_integer(submission_id)
    {:ok, submission} = Submission.add_tag(submission_id, tag, socket.assigns.current_scope)

    new_submissions =
      socket.assigns.submissions
      |> Enum.map(fn s ->
        if s.id == submission.id, do: Map.put(s, :tags, submission.tags), else: s
      end)

    {:noreply,
     socket
     |> assign(:submissions, new_submissions)
     |> push_patch(to: ~p"/admin/quiz/#{socket.assigns.quiz.id}/submissions")}
  end

  @impl true
  def handle_event("remove_tag", %{"submission-id" => submission_id, "tag" => tag}, socket) do
    submission_id = String.to_integer(submission_id)
    {:ok, submission} = Submission.remove_tag(submission_id, tag, socket.assigns.current_scope)

    new_submissions =
      Enum.map(socket.assigns.submissions, fn s ->
        if s.id == submission.id, do: Map.put(s, :tags, submission.tags), else: s
      end)

    {:noreply,
     socket
     |> assign(:submissions, new_submissions)
     |> push_patch(to: ~p"/admin/quiz/#{socket.assigns.quiz.id}/submissions")}
  end

  @impl true
  def handle_event("show_url", %{"submission_id" => submission_id}, socket) do
    submission_id = String.to_integer(submission_id)
    submission = socket.assigns.submissions |> Enum.find(&(&1.id == submission_id))
    encoded_secret = SecretUrl.secret_url(submission.secret)

    url =
      URI.parse(socket.assigns.current_uri)
      |> Map.put(:path, ~p"/quiz/#{socket.assigns.quiz.slug}")
      |> Map.put(:query, "secret=#{encoded_secret}")
      |> Map.put(:fragment, nil)
      |> URI.to_string()

    {:noreply, socket |> assign(show_copy_url: url, show_copy_url_name: submission.name)}
  end

  @impl true
  def handle_event("hide_url", _, socket) do
    {:noreply, socket |> assign(show_copy_url: nil, show_copy_url_name: nil)}
  end

  @impl true
  def handle_event("show_delete_submission_modal", %{"submission_id" => submission_id}, socket) do
    submission =
      Submission.get_submission(
        socket.assigns.quiz.id,
        submission_id,
        socket.assigns.current_scope
      )

    {:noreply,
     socket |> assign(show_delete_submission_modal: submission, show_copy_url_name: nil)}
  end

  def handle_event("hide_delete_submission_modal", _, socket) do
    # grrr
    {:noreply, assign(socket, show_delete_submission_modal: nil)}
  end

  def handle_info({Form.DeleteSubmissionForm, {:canceled}}, socket) do
    {:noreply, assign(socket, show_delete_submission_modal: nil)}
  end

  def handle_info({Form.DeleteSubmissionForm, {:deleted, submission}}, socket) do
    submissions = Enum.filter(socket.assigns.submissions, &(&1.id != submission.id))

    {:noreply, assign(socket, submissions: submissions, show_delete_submission_modal: nil)}
  end
end
