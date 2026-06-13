defmodule AndaWeb.AnswersLive.Index do
  use AndaWeb, :live_view
  alias Anda.Contest
  alias Anda.Submission
  alias Anda.Contest.QuizUtils

  defp get_sortable_value_for(submission, q_id) do
    answer = Map.get(submission.answers_by_question_id, q_id)

    cond do
      is_nil(answer) ->
        nil

      is_nil(answer.text) ->
        nil

      answer.type == "number" && answer.num_answers == 1 ->
        String.to_integer(answer.text)

      answer.type == "football-score" && answer.num_answers == 1 ->
        sum = answer.text |> String.split("-") |> Enum.map(&String.to_integer/1) |> Enum.sum()
        "#{String.pad_leading("#{sum}", 2, "0")}-#{answer.text}"

      is_binary(answer.text) ->
        answer.text
        |> String.downcase()
        |> String.normalize(:nfkd)
    end
  end

  def sort_submissions(submissions, sort_order) do
    sorter =
      case sort_order do
        "name_asc" ->
          &(&1.name <= &2.name)

        "name_desc" ->
          &(&1.name >= &2.name)

        "question_" <> rest ->
          [num, dir] = String.split(rest, "_")
          q_id = String.to_integer(num)

          case dir do
            "asc" ->
              fn sa, sb ->
                a = get_sortable_value_for(sa, q_id)
                b = get_sortable_value_for(sb, q_id)
                a <= b
              end

            "desc" ->
              fn sa, sb ->
                a = get_sortable_value_for(sa, q_id)
                b = get_sortable_value_for(sb, q_id)
                a >= b
              end
          end
      end

    Enum.sort(submissions, sorter)
  end

  def get_answers(submission, selected_questions) do
    Enum.map(selected_questions, fn q ->
      a = Map.get(submission.answers_by_question_id, q.id)
      a && %{text: a.text, score: a.score}
    end)
  end

  def get_submissions(quiz_id, tag \\ nil, section \\ nil) do
    Submission.get_all_submissions_with_answers(quiz_id, tag, section)
    |> Enum.map(fn s ->
      Map.put(
        s,
        :answers_by_question_id,
        Enum.reduce(s.answers, %{}, fn e, acc ->
          Map.put(acc, e.id, e)
        end)
      )
    end)
  end

  def mount(%{"slug" => slug, "tag_with_mac" => tag_with_mac}, _session, socket)
      when socket.assigns.live_action == :public do
    quiz =
      Contest.get_quiz_w_questions_by_slug(slug)
      |> QuizUtils.calculate_ranks()

    {:ok, tag} = Mac.verify_added_mac(tag_with_mac)
    tag = if tag == "", do: nil, else: tag

    {:ok,
     socket
     |> assign_new(:current_scope, fn -> nil end)
     |> assign(:page_title, "#{quiz.title} - Svar")
     |> assign(:quiz, quiz)
     |> assign(:tag_with_mac, tag_with_mac)
     |> assign(:tag, tag)}
  end

  def mount(%{"quiz_id" => quiz_id}, _session, socket)
      when socket.assigns.live_action == :private do
    quiz =
      Contest.get_quiz_w_questions(quiz_id, socket.assigns.current_scope)
      |> QuizUtils.calculate_ranks()

    {:ok,
     socket
     |> assign_new(:current_scope, fn -> nil end)
     |> assign(:quiz, quiz)}
  end

  def handle_params(params, uri, socket)
      when socket.assigns.live_action == :public do
    quiz = socket.assigns.quiz
    sort_order = Map.get(socket.assigns, :sort_order, "name_asc")
    submissions = get_submissions(quiz.id, socket.assigns.tag)

    selected_section = Map.get(params, "section")

    selected_section =
      if selected_section, do: String.to_integer(selected_section), else: selected_section

    selected_questions = QuizUtils.get_all_questions(quiz, selected_section)

    {:noreply,
     socket
     |> assign(:quiz, quiz)
     |> assign(:tags, nil)
     |> assign(:show_copy_url, nil)
     |> assign(:selected_tag, nil)
     |> assign(:selected_section, selected_section)
     |> assign(:selected_questions, selected_questions)
     |> assign(current_uri: uri)
     |> assign(:sort_order, sort_order)
     |> assign(:submissions, sort_submissions(submissions, sort_order))}
  end

  @impl true
  def handle_params(%{"quiz_id" => quiz_id} = params, uri, socket)
      when socket.assigns.live_action == :private do
    quiz = socket.assigns.quiz
    sort_order = Map.get(socket.assigns, :sort_order, "name_asc")
    selected_section = Map.get(params, "section")

    selected_section =
      if selected_section, do: String.to_integer(selected_section), else: selected_section

    tags = Submission.get_all_tags(quiz_id)
    selected_tag = Map.get(params, "tag")

    submissions = get_submissions(quiz.id, selected_tag)

    selected_questions = QuizUtils.get_all_questions(quiz, selected_section)

    {:noreply,
     socket
     |> assign(:quiz, quiz)
     |> assign(:tags, tags)
     |> assign(:selected_tag, selected_tag)
     |> assign(:selected_section, selected_section)
     |> assign(:selected_questions, selected_questions)
     |> assign(:show_copy_url, nil)
     |> assign(current_uri: uri)
     |> assign_new(:sort_order, fn -> sort_order end)
     |> assign(:submissions, sort_submissions(submissions, sort_order))}
  end

  @impl true
  def handle_event("change_tag", %{"tag" => tag}, socket) do
    url =
      if tag == "" do
        ~p"/admin/quiz/#{socket.assigns.quiz.id}/answers"
      else
        ~p"/admin/quiz/#{socket.assigns.quiz.id}/answers?tag=#{tag}"
      end

    {:noreply, socket |> push_patch(to: url)}
  end

  @impl true
  def handle_event("change_section", %{"section" => section}, socket)
      when socket.assigns.live_action == :private do
    url =
      if section == "" do
        ~p"/admin/quiz/#{socket.assigns.quiz.id}/answers"
      else
        ~p"/admin/quiz/#{socket.assigns.quiz.id}/answers?section=#{section}"
      end

    {:noreply, socket |> push_patch(to: url)}
  end

  @impl true
  def handle_event("change_section", %{"section" => section}, socket)
      when socket.assigns.live_action == :public do
    url =
      if section == "" do
        ~p"/quiz/#{socket.assigns.quiz.slug}/answers/#{socket.assigns.tag_with_mac}"
      else
        ~p"/quiz/#{socket.assigns.quiz.slug}/answers/#{socket.assigns.tag_with_mac}?section=#{section}"
      end

    {:noreply, socket |> push_patch(to: url)}
  end

  @impl true
  def handle_event("set_sort_order", %{"sort_order" => sort_order}, socket) do
    {:noreply,
     assign(socket,
       sort_order: sort_order,
       submissions: sort_submissions(socket.assigns.submissions, sort_order)
     )}
  end

  @impl true
  def handle_event("show_url", _, socket) do
    tag_with_mac = Mac.add_mac(socket.assigns.selected_tag || "")

    url =
      URI.parse(socket.assigns.current_uri)
      |> Map.put(:path, ~p"/quiz/#{socket.assigns.quiz.slug}/answers/#{tag_with_mac}")
      |> Map.put(:query, nil)
      |> URI.to_string()

    {:noreply, socket |> assign(show_copy_url: url)}
  end

  @impl true
  def handle_event("hide_url", _, socket) do
    {:noreply, socket |> assign(show_copy_url: nil)}
  end
end
