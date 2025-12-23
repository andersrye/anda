defmodule AndaWeb.QuizLive.Edit do
  alias AndaWeb.Endpoint
  use AndaWeb, :live_view

  alias Anda.Contest
  alias Phoenix.PubSub
  alias AndaWeb.QuizLive.Form

  @impl true
  def mount(%{"quiz_id" => id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Anda.PubSub, "quiz:#{id}:new_answer")
      Endpoint.subscribe("quiz:#{id}:section")
    end

    {:ok,
     socket
     |> assign(:page_title, "Quiz")
     |> assign(:quiz, Contest.get_quiz!(id))
     |> assign(:sections, Contest.list_sections(id))}
  end

  @impl true
  def handle_params(params, _, socket) do
    parsed_params =
      for {k, v} when k in ["quiz_id", "section_id", "question_id"] <- params, into: %{} do
        {String.to_atom(k), String.to_integer(v)}
      end

    {:noreply, socket |> assign(parsed_params)}
  end

  @impl true
  def handle_info({Form.SectionForm, {:saved, section}}, socket) do
    {:noreply, stream_insert(socket, :sections, section)}
  end

  @impl true
  def handle_info({Form.QuestionForm, {:saved, _question}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({Form.QuizForm, {:saved, quiz}}, socket) do
    {:noreply, assign(socket, :quiz, quiz)}
  end

  @impl true
  def handle_info(
        {:new_answer, %{:section_id => section_id, :question_id => question_id}},
        socket
      ) do
    send_update(AndaWeb.QuizLive.Section, id: "sections-#{section_id}", new_answer: question_id)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated_question, question}, socket) do
    send_update(AndaWeb.QuizLive.Section,
      id: "sections-#{question.section_id}",
      updated_question: question
    )

    {:noreply, socket |> push_patch(to: ~p"/admin/quiz/#{socket.assigns.quiz_id}")}
  end

  @impl true
  def handle_info({:scored_question}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/admin/quiz/#{socket.assigns.quiz_id}")}
  end

  @impl true
  def handle_info(%{event: "section_updated", payload: sections}, socket) do
    {:noreply, socket |> assign(:sections, sections)}
  end

  @impl true
  def handle_event("delete_question", %{"question_id" => question_id}, socket) do
    question = Contest.get_question!(question_id)
    Contest.delete_question(question)

    send_update(AndaWeb.QuizLive.Section,
      id: "sections-#{question.section_id}",
      deleted_question: question
    )

    {:noreply, socket |> push_patch(to: ~p"/admin/quiz/#{socket.assigns.quiz_id}")}
  end

  @impl true
  def handle_event("change_mode", %{"mode" => mode}, socket) do
    with {:ok, quiz} =
           Contest.update_quiz(
             socket.assigns.quiz,
             %{"mode" => mode},
             socket.assigns.current_scope
           ) do
      {:noreply,
       socket
       |> assign(quiz: quiz)
       |> put_flash(
         :info,
         "Quizen er nå #{case mode do
           "hidden" -> "skjult"
           "open" -> "åpen"
           "closed" -> "stengt"
           _ -> "??"
         end}!"
       )}
    else
      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Oops, det funka ikke!")}
    end
  end
end
